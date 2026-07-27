# ~/.zshrc から source される関数定義集。
# 各機能(fzf履歴・fssm補完など)は登録(zle/bindkey/compdef)も含めて自己完結させる。
# compdef を使うため、compinit 後に source されること(.zshrc がその順で呼ぶ)。

# gs の変更ファイルを一括で nvim で開く
vi_edit() {
  gs | grep '^[ M]' | awk '{print $2}' | xargs nvim
}

# === AWS 汎用ツール(会社非依存) ===

# fssm: fzf で実行中の EC2 / ECS を選んで SSM 接続する
_fssm_completions() {
  _arguments '1: :->subcommand'
  case "$state" in
    subcommand)
      _values $state \
        'ec2[EC2]' \
        'ecs[ECS]'
      ;;
  esac
}
compdef _fssm_completions fssm

function fssm() {
  case "$1" in
    ec2)
      local target_line=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].{Id:InstanceId, Name:Tags[?Key=='Name'].Value|[0], IP:PrivateIpAddress, AZ:Placement.AvailabilityZone}" \
        --output json | \
        jq -r '.[] | [.Id, (.Name // "<No Name>"), .IP, .AZ] | @tsv' | \
        sort -k2 | \
        column -t -s $'\t' | \
        fzf --prompt="Select EC2 Instance (ECS or Ctrl+C to cancel)> " --header="Instance ID | Name | Private IP | AZ")
      [ -z "$target_line" ] && return 1

      local instance_id=$(echo "$target_line" | awk '{print $1}')
      local instance_name=$(echo "$target_line" | awk '{print $2}')
      echo "Connecting to..."
      echo "Instance ID: $instance_id"
      echo "Name:        $instance_name"
      echo "----------------------------------------"
      aws ssm start-session --target "$instance_id"
      ;;
    ecs)
      local cluster=$(aws ecs list-clusters --query 'clusterArns[]' --output text | \
        tr '\t' '\n' | \
        awk -F/ '{print $NF}' | \
        sort | \
        fzf --prompt="Select Cluster (ESC or Ctrl+C to cancel)> " --header="Cluster Name")

      [ -z "$cluster" ] && return 1

      local task_arns=$(aws ecs list-tasks --cluster "$cluster" --desired-status RUNNING --query 'taskArns[]' --output text)
      if [ -z "$task_arns" ]; then
        echo "No running tasks found in cluster: $cluster" >&2
        return 1
      fi

      local target_line=$(echo "$task_arns" | xargs -n 100 aws ecs describe-tasks --cluster "$cluster" --output json --tasks | \
        jq -r '.tasks[] | .taskArn as $arn | .group as $group | .containers[] | [$group, ($arn | split("/") | last), .name, .runtimeId] | @tsv' | \
        column -t -s $'\t' | \
        fzf --prompt="Select Container (ECS or Ctrl+C to cancel)> " \
        --header="Service/Group | Task ID | Container Name | Runtime ID")

      [ -z "$target_line" ] && return 1

      local task_id=$(echo "$target_line" | awk '{print $2}')
      local container_name=$(echo "$target_line" | awk '{print $3}')
      echo "Connecting to..."
      echo "Cluster:   $cluster"
      echo "Task:      $task_id"
      echo "Container: $container_name"
      echo "----------------------------------------"
      aws ecs execute-command --cluster "$cluster" --task "$task_id" --container "$container_name" --command "/bin/sh" --interactive
      ;;
    *)
      echo "Usage: fssm <ec2|ecs>"
      return 1
      ;;
  esac
}

# frds: fzf で Aurora を選んで bastion 経由のポートフォワード + mysql 接続する。
# bastion 名は ${BASTION_PREFIX}-<env>-bastion (BASTION_PREFIX は private 側で設定)
function frds() {
  local bastion_name="${BASTION_PREFIX:-toro}-$1-bastion"
  local selected_line=$(aws rds describe-db-clusters \
    --query "DBClusters[].{ID:DBClusterIdentifier, Host:Endpoint, Port:Port, Arn:MasterUserSecret.SecretArn}" \
    --output json | \
    jq -r '.[] | "\(.ID)\t\(.Host)\t\(.Port)\t\(.Arn)"' | \
    column -t -s $'\t' | \
    fzf --prompt="Aurora Cluster を選択してください (ECS or Ctrl+C to cancel)> ")
  [ -z "$selected_line" ] && return 0

  local db_host=$(echo "$selected_line" | awk '{print $2}')
  local db_port=$(echo "$selected_line" | awk '{print $3}')
  local secret_arn=$(echo "$selected_line" | awk '{print $4}')
  if [[ "$secret_arn" == "null" ]] || [[ -z "$secret_arn" ]]; then
    echo "エラー: この Cluster に紐付けられた Secret Manager がありません" >&2
    return 1
  fi

  echo "紐付けられた Secret Manager から認証情報を取得中..."
  local secret_json=$(aws secretsmanager get-secret-value --secret-id "$secret_arn" --query SecretString --output text)
  local db_user=$(echo "$secret_json" | jq -r '.username')
  local db_pass=$(echo "$secret_json" | jq -r '.password')

  local local_port=$((10000 + RANDOM % 50000))
  echo "$bastion_name 経由で接続中：$db_host:$db_port -> localhost:$local_port"
  local bastion_id=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${bastion_name}" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)
  set +m
  aws ssm start-session --target "$bastion_id" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$db_host\"],\"portNumber\":[\"$db_port\"], \"localPortNumber\":[\"$local_port\"]}" > /dev/null 2>&1 &
  local ssm_pid=$!
  set -m
  trap "kill $ssm_pid 2>/dev/null" EXIT
  sleep 2

  MYSQL_PWD="$db_pass" mysql -h 127.0.0.1 -P "$local_port" -u "$db_user"
}
