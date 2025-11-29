-- lua/plugins/copilot.lua

return {
  "github/copilot.vim",
  -- Copilotが起動の邪魔をしないように、起動完了後に読み込む
  event = "VimEnter",
  config = function()
    -- --- オプション設定 ---
    vim.g.copilot_node_command = os.getenv("HOME") .. "/.local/share/mise/installs/node/24.6.0/bin/node"

    -- Tabキーでの補完を無効化する（他の補完プラグインとの競合を避けるため）
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true -- 上記設定とセットで使う

    vim.g.copilot_auto_enable = true -- 自動で有効化 
    -- --- キーマップ設定 ---
    local map = vim.keymap.set
    local modes = {"n", "i"} -- ノーマルモードとインサートモードで設定

    -- 提案を受け入れる（Accept）
    -- Ctrl + L に割り当て。複数行の提案も一度に受け入れられる
    map(modes, "<C-l>", 'copilot#Accept("<CR>")', {
      expr = true,
      replace_keycodes = false,
    })

    -- 次の提案へ（Next）
    map(modes, "<C-j>", "<Plug>(copilot-next)")

    -- 前の提案へ（Previous）
    map(modes, "<C-k>", "<Plug>(copilot-prev)")

    -- 提案を閉じる（Dismiss）
    map(modes, "<C-h>", "<Plug>(copilot-dismiss)")
  end,
}
