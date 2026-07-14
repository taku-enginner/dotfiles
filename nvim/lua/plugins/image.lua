return {
  "3rd/image.nvim",
  -- 画像ファイルを開いた瞬間に hijack して描画するため、起動時にロードして
  -- setup() の autocmd 登録を最初のファイル読み込みより前に済ませる
  -- (画像ファイルは filetype が空なので ft 遅延ロードでは発火しない)
  lazy = false,
  opts = {
    -- Kitty graphics protocol を採用。kitty backend は tmux passthrough 対応で
    -- tmux 内でも再描画される。Mac の iTerm2(3.5.6+)や Kitty/Ghostty/Linux版
    -- WezTerm で動作する。
    -- 注意: Windows 版 WezTerm は kitty protocol 非対応なので Windows 経路
    -- (WezTerm→WSL→ssh)では描画されない。そちらは imgcat(.zshrc・iTerm2
    -- protocol)を tmux 外で使う運用。
    backend = "kitty",
    -- luarocks(magick rock)を避け、ImageMagick CLI を直接利用
    processor = "magick_cli",
    integrations = {
      -- render-markdown.nvim と併用。markdown 内の画像を表示
      markdown = {
        enabled = true,
        only_render_image_at_cursor = false,
      },
    },
    -- 画像ファイルを直接開いたときに画像として描画
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    -- ウィンドウ重なり時に画像をクリアしてゴミ表示を防ぐ
    window_overlap_clear_enabled = true,
    editor_only_render_when_focused = false,
    tmux_show_only_in_active_window = true,
  },
}
