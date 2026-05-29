return {
  -- コメント化プラグイン。<leader>cc でコメント、<leader>c<Space> でトグル、
  -- <leader>cu で解除（デフォルトマッピングをプラグインが自動生成）。
  -- 旧 config は Neovim では常に早期 return する死にコードだったため撤去し、
  -- プラグイン標準動作に委ねる。挙動の変更なし。
  'preservim/nerdcommenter',
  event = "VeryLazy",
}
