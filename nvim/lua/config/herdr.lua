-- herdr のペイン越しに Claude Code へプロンプトを送る連携。
-- 左=Claude Code / 右=nvim(下書き)で使う。ペインは `cc-compose` が開く。
--   :CcSend    バッファ(または選択範囲)を Claude の入力欄に入れる(送信はしない)
--   :CcSubmit  入れたうえで送信キーまで送る
--   :CcTarget  送信先ペインの確認 / 固定(`:CcTarget wE:pJ`) / 解除(`:CcTarget clear`)
-- 送信キーは dotfiles/claude/keybindings.json の chat:submit と合わせること。
local SUBMIT_KEY = "ctrl+f"

-- herdr CLI を叩いて JSON を返す(失敗時は nil)
local function herdr(args)
  local res = vim.system(vim.list_extend({ "herdr" }, args), { text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, res.stdout or "")
  return ok and data or nil
end

local function pane_info(id)
  local d = herdr({ "pane", "get", id })
  return d and d.result and d.result.pane or nil
end

-- 同じタブにいる Claude Code のペイン(自分以外)を pane_id => agent で返す
local function candidates(me, tab)
  local d = herdr({ "agent", "list" })
  local set, count = {}, 0
  for _, a in ipairs(d and d.result and d.result.agents or {}) do
    if a.pane_id ~= me and (not tab or a.tab_id == tab) then
      set[a.pane_id] = a
      count = count + 1
    end
  end
  return set, count
end

-- レイアウトの座標で送信先を決める。
-- 「自分の左にあって縦に重なる」候補のうち最も近いもの(= x が最大)を選ぶ。
-- 左に無ければ画面左端に近い候補を選ぶ(候補が複数でも結果が揺れないようにする)。
local function pick_by_layout(me, set)
  local d = herdr({ "pane", "layout", "--pane", me })
  local panes = d and d.result and d.result.layout and d.result.layout.panes or {}
  local mine
  for _, p in ipairs(panes) do
    if p.pane_id == me then
      mine = p.rect
    end
  end
  if not mine then
    return nil
  end

  local left, left_x, any, any_x
  for _, p in ipairs(panes) do
    local r = p.rect
    if set[p.pane_id] and r then
      if not any_x or r.x < any_x or (r.x == any_x and p.pane_id < any) then
        any, any_x = p.pane_id, r.x
      end
      local overlaps_vertically = r.y < mine.y + mine.height and mine.y < r.y + r.height
      if r.x + r.width <= mine.x and overlaps_vertically then
        if not left_x or r.x > left_x or (r.x == left_x and p.pane_id < left) then
          left, left_x = p.pane_id, r.x
        end
      end
    end
  end
  return left or any
end

local function claude_pane()
  local me, tab = vim.env.HERDR_PANE_ID, vim.env.HERDR_TAB_ID
  if not me then
    return nil, "herdr のペイン内で実行すること"
  end

  -- 1. :CcTarget での明示指定が最優先
  local pinned = vim.g.cc_pane
  if pinned and pinned ~= "" then
    if pane_info(pinned) then
      return pinned
    end
    return nil, ("固定した送信先 %s が見つからない(:CcTarget clear で解除)"):format(pinned)
  end

  local set, count = candidates(me, tab)

  -- 2. cc-compose が分割元として渡したペイン(推測が要らないので最優先で使う)
  local from = vim.env.CC_TARGET_PANE
  if from and from ~= "" and (set[from] or pane_info(from)) then
    return from
  end

  if count == 0 then
    return nil, "同じタブに Claude Code のペインが無い"
  end
  -- 3. 座標から決める。取れなければ pane_id 順(決定的なら誤送信に気づける)
  if count > 1 then
    local picked = pick_by_layout(me, set)
    if picked then
      return picked
    end
    local ids = vim.tbl_keys(set)
    table.sort(ids)
    return ids[1]
  end
  return (next(set))
end

local function send(lines, submit, whole_buffer)
  local pane, err = claude_pane()
  if not pane then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local text = table.concat(lines, "\n")
  if text:match("^%s*$") then
    vim.notify("送る内容が空", vim.log.levels.WARN)
    return
  end
  if not herdr({ "agent", "send", pane, text }) then
    vim.notify("herdr agent send に失敗", vim.log.levels.ERROR)
    return
  end
  if submit then
    herdr({ "pane", "send-keys", pane, SUBMIT_KEY })
  end

  -- 下書き用スクラッチを丸ごと送ったときだけ空にして次のプロンプトに備える
  -- (通常のソースファイルを消さないようファイル名で限定する)
  if whole_buffer and vim.fn.expand("%:t"):match("^cc%-prompt%-") then
    vim.cmd("silent %delete _")
    vim.cmd("silent write")
  end

  -- 送信先を必ず出す(ペインが複数あるとき誤送信にすぐ気づけるように)。
  -- 細いペインで切られても宛先が読めるよう、ペイン ID を先頭に置く
  vim.b.cc_target = pane
  local info = pane_info(pane) or {}
  vim.notify(("→%s %d行%s %s"):format(
    pane,
    #lines,
    submit and " submit" or "",
    info.cwd and vim.fn.fnamemodify(info.cwd, ":~") or ""
  ))
end

-- 下書きバッファの winbar に「送信先」と操作キーを常時出す。
-- (送信先の解決は CLI を叩くのでバッファ変数にキャッシュし、再描画では再計算しない)
local function cached_target()
  if vim.b.cc_target == nil then
    vim.b.cc_target = claude_pane() or ""
  end
  return vim.b.cc_target
end

function _G.CcWinbar()
  local target = cached_target()
  local head = target ~= "" and ("→" .. target) or "→送信先なし"
  if vim.api.nvim_win_get_width(0) < 56 then
    return head
  end
  return head .. "  SPC cc 入力 / SPC cs 送信 / :q 閉じる"
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "FocusGained" }, {
  pattern = "*/cc-prompt-*.md",
  group = vim.api.nvim_create_augroup("cc_prompt_winbar", { clear = true }),
  callback = function()
    vim.b.cc_target = nil -- レイアウトが変わっている可能性があるので取り直す
    vim.wo.winbar = "%!v:lua.CcWinbar()"
  end,
})

local function cmd(submit)
  return function(o)
    local whole = o.range == 0 -- 範囲指定なし = バッファ全体
    local lines = whole and vim.api.nvim_buf_get_lines(0, 0, -1, false)
      or vim.api.nvim_buf_get_lines(0, o.line1 - 1, o.line2, false)
    send(lines, submit, whole)
  end
end

vim.api.nvim_create_user_command("CcSend", cmd(false), { range = true, desc = "Claude Code の入力欄へ入れる" })
vim.api.nvim_create_user_command("CcSubmit", cmd(true), { range = true, desc = "Claude Code へ入れて送信" })

vim.api.nvim_create_user_command("CcTarget", function(o)
  if o.args == "" then
    local pane, err = claude_pane()
    if not pane then
      vim.notify(err, vim.log.levels.WARN)
      return
    end
    local info = pane_info(pane) or {}
    vim.notify(("送信先: %s%s"):format(pane, info.cwd and (" " .. vim.fn.fnamemodify(info.cwd, ":~")) or ""))
    return
  end
  if o.args == "clear" then
    vim.g.cc_pane = nil
    vim.b.cc_target = nil -- winbar を再解決させる
    vim.notify("送信先の固定を解除")
    return
  end
  vim.g.cc_pane = o.args
  vim.b.cc_target = o.args
  vim.notify("送信先を固定: " .. o.args)
end, { nargs = "?", desc = "Claude Code の送信先ペインを確認/固定" })

vim.keymap.set("n", "<leader>cc", "<cmd>CcSend<CR>", { desc = "Claude Code へ本文を送る" })
vim.keymap.set("x", "<leader>cc", ":CcSend<CR>", { desc = "Claude Code へ選択範囲を送る" })
vim.keymap.set("n", "<leader>cs", "<cmd>CcSubmit<CR>", { desc = "Claude Code へ送って送信" })
vim.keymap.set("x", "<leader>cs", ":CcSubmit<CR>", { desc = "Claude Code へ選択範囲を送って送信" })
