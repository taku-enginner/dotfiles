return {
  'preservim/nerdcommenter',
  -- プラグインがロードされた後に実行される設定
  config = function()
    -- 1. 初期チェックとロード制御の再現
    -- LuaでNeovimのバージョンチェックを行う
    if vim.version().major < 7 then
      vim.api.nvim_echo({{
        -- ★★★ 修正箇所: 文字列を [[...]] に変更し、エスケープを削除 ★★★
        [[NERDCommenter: this plugin requires vim >= 7. DOWNLOAD IT! You'll thank me later!]],
        'Error',
      }}, true, {})
      return
    end
    -- loaded_nerd_comments 変数の設定 (プラグイン本体が通常行いますが、再現として)
    vim.g.loaded_nerd_comments = 1

    -- 2. 変数の初期化 (元の call s:InitVariable を vim.g で直接設定)
    -- s:InitVariableのロジック(existsチェック)は不要なため、デフォルト値を直接設定します。
    -- 変数名に存在するコロン(::)はLuaでは使用できないため、文字列としてアクセスします。

    -- [g:NERD* 変数の設定]
    vim.g.NERDAllowAnyVisualDelims = 1
    vim.g.NERDBlockComIgnoreEmpty = 0
    vim.g.NERDCommentWholeLinesInVMode = 0
    vim.g.NERDCommentEmptyLines = 0
    vim.g.NERDCompactSexyComs = 0
    vim.g.NERDCreateDefaultMappings = 1 -- ★デフォルトマッピングを有効化
    vim.g.NERDDefaultNesting = 1
    vim.g.NERDMenuMode = 3
    vim.g.NERDLPlace = '[>'
    vim.g.NERDUsePlaceHolders = 1
    vim.g.NERDRemoveAltComs = 1
    vim.g.NERDRemoveExtraSpaces = 0
    vim.g.NERDRPlace = '<]'
    vim.g.NERDSpaceDelims = 0
    vim.g.NERDDefaultAlign = 'none'
    vim.g.NERDTrimTrailingWhitespace = 0
    vim.g.NERDToggleCheckAllLines = 0
    vim.g.NERDDisableTabsInBlockComm = 0
    vim.g.NERDSuppressWarnings = 0

    -- 3. マッピングとメニュー項目の設定 (call s:CreateMaps の再現)

    local create_maps_calls = [[
      call s:CreateMaps('nx', 'Comment',   'Comment', 'cc')
      call s:CreateMaps('nx', 'Toggle',    'Toggle', 'c<Space>')
      call s:CreateMaps('nx', 'Minimal',   'Minimal', 'cm')
      call s:CreateMaps('nx', 'Nested',    'Nested', 'cn')
      call s:CreateMaps('n',  'ToEOL',     'To EOL', 'c$')
      call s:CreateMaps('nx', 'Invert',    'Invert', 'ci')
      call s:CreateMaps('nx', 'Sexy',      'Sexy', 'cs')
      call s:CreateMaps('nx', 'Yank',      'Yank then comment', 'cy')
      call s:CreateMaps('n',  'Append',    'Append', 'cA')
      call s:CreateMaps('',   ':',         '-Sep-', '')
      call s:CreateMaps('nx', 'AlignLeft', 'Left aligned', 'cl')
      call s:CreateMaps('nx', 'AlignBoth', 'Left and right aligned', 'cb')
      call s:CreateMaps('',   ':',         '-Sep2-', '')
      call s:CreateMaps('nx', 'Uncomment', 'Uncomment', 'cu')
      call s:CreateMaps('n',  'AltDelims', 'Switch Delimiters', 'ca')
      call s:CreateMaps('i',  'Insert',    'Insert Comment Here', '')
      call s:CreateMaps('',   ':',         '-Sep3-', '')
      call s:CreateMaps('',   ':help NERDCommenterContents<CR>', 'Help', '')
    ]]
    vim.cmd(create_maps_calls)

    -- 4. 互換性マッピングの再現
    vim.cmd([[
      inoremap <silent> <Plug>NERDCommenterInsert <C-\><C-O>:call nerdcommenter#Comment('i', "Insert")<CR>
      nnoremap <Plug>NERDCommenterAltDelims :call nerdcommenter#SwitchToAlternativeDelimiters(1)<CR>
    ]])
  end,
}
