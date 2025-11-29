# dotfiles
### インストール手順（案件）
前提：たいてい必要なソフトウェアは入っている（sudo git vim curl zsh）
```
cd && \
mkdir .config && \
git clone https://github.com/taku-enginner/dotfiles.git && \
~/dotfiles/setup.sh && \
```
---

### インストール手順(ubuntuの空コンテナの場合）
必要なソフトウェアのインストール && ユーザー追加 & パスワード設定
```
apt update && \
apt install sudo git vim curl zsh -y && \
useradd -m tak -s /usr/bin/zsh && \
passwd tak && \
cp /etc/sudoers /etc/backup_sudoers && visudo && \
su tak
```

```
tak ALL=(ALL) ALL 
```

ディレクトリ準備 && git clone && setup.shの実行 && mise trust && mise のプラグインインストール
```
cd && \
mkdir .config && \
git clone https://github.com/taku-enginner/dotfiles.git && \
~/dotfiles/setup.sh && \
source ~/dotfiles/.zshrc && \
mise list && ~/dotfiles/setup.sh
```
HTTP経由のclone時に認証で「パスワードが廃止された」と言われるので、デスクトップのメモ帳にあるトークンを使用する。
もしくはGitHubのsettings -> Developer settings -> Personal access tokens -> Tokens(classic) からトークンを発行し、パスワードとして入力する。


### プロジェクト途中参画の場合
cloneあたりから実行

### dockerコンテナ
コンテナ立ち上げ
```
docker run -it ubuntu
```
コンテナに再度入る
```
docker start コンテナID
docker container exec -it コンテナID bash
```
ubuntuコンテナをすべて削除する（※注意！）
```
docker stop $(docker ps -a --filter "ancestor=ubuntu" --format "{{.ID}}")
docker rm $(docker ps -a --filter "ancestor=ubuntu" --format "{{.ID}}")
```
