-- agentwatch: poll watched buffers for on-disk changes (e.g. from a coding
-- agent editing files externally) and highlight recent edits with a fading
-- diff-style gradient. Toggle globally with :AgentWatchToggle.

local uv = vim.uv or vim.loop

local M = {}

local POLL_INTERVAL_MS = 500
local FADE_INTERVAL_MS = 1000
local MAX_AGE_SEC = 30 -- TESTING: 5 buckets over 30s (6s each); restore to 3600
local AGE_BUCKETS = 5

local ADD_COLORS = { "#1e3a8a", "#2f52a8", "#3b82f6", "#60a5fa", "#93c5fd" }
local DEL_COLORS = { "#7f1d1d", "#a3231f", "#b91c1c", "#dc2626", "#ef4444" }

local ns = vim.api.nvim_create_namespace("agentwatch")
local augroup = nil

local enabled = false
local poll_timer = nil
local fade_timer = nil
local buf_state = {} -- bufnr -> { path, last_lines, last_mtime, hunks }

local function define_highlights()
  for i, c in ipairs(ADD_COLORS) do
    vim.api.nvim_set_hl(0, "AgentWatchAdd" .. i, { bg = c })
    vim.api.nvim_set_hl(0, "AgentWatchAddLabel" .. i, { fg = c, italic = true })
  end
  for i, c in ipairs(DEL_COLORS) do
    vim.api.nvim_set_hl(0, "AgentWatchDel" .. i, { bg = c })
    vim.api.nvim_set_hl(0, "AgentWatchDelLabel" .. i, { fg = c, italic = true })
  end
end

local function format_age(elapsed_sec)
  if elapsed_sec < 10 then
    return "just now"
  elseif elapsed_sec < 60 then
    return string.format("%ds ago", math.floor(elapsed_sec))
  elseif elapsed_sec < 3600 then
    return string.format("%dm ago", math.floor(elapsed_sec / 60))
  else
    return string.format("%dh ago", math.floor(elapsed_sec / 3600))
  end
end

local function is_watchable(bufnr)
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and vim.fn.filereadable(name) == 1
end

local function file_mtime_ns(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return nil
  end
  return stat.mtime.sec * 1e9 + stat.mtime.nsec
end

local function register_buf(bufnr)
  if buf_state[bufnr] or not is_watchable(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  buf_state[bufnr] = {
    path = path,
    last_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    last_mtime = file_mtime_ns(path),
    hunks = {},
  }
end

local function unregister_buf(bufnr)
  buf_state[bufnr] = nil
end

-- Usable text width of the window showing bufnr (for right-aligning labels
-- inside virt_lines, which right_align virt_text doesn't apply to).
local function text_width(bufnr)
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return vim.o.columns
  end
  local info = vim.fn.getwininfo(win)[1]
  return info.width - info.textoff
end

local function del_vlines(width, lines, label, hl, label_hl)
  local vlines = {}
  local label_w = vim.fn.strdisplaywidth(label)
  for _, line in ipairs(lines) do
    local pad = math.max(width - vim.fn.strdisplaywidth(line) - label_w, 1)
    table.insert(vlines, { { line, hl }, { string.rep(" ", pad), hl }, { label, label_hl } })
  end
  return vlines
end

local function add_hunk(bufnr, row_start, row_end)
  local ids = {}
  local label = " +" .. format_age(0)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  for row = row_start, row_end do
    if row < line_count then
      local id = vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
        end_row = math.min(row + 1, line_count),
        end_col = 0,
        hl_group = "AgentWatchAdd1",
        hl_eol = true,
        virt_text = { { label, "AgentWatchAddLabel1" } },
        virt_text_pos = "right_align",
      })
      table.insert(ids, id)
    end
  end
  table.insert(buf_state[bufnr].hunks, {
    type = "add",
    extmark_ids = ids,
    birth = uv.hrtime(),
  })
end

local function del_hunk(bufnr, anchor_row, above, lines)
  local label = "-" .. format_age(0) .. " "
  local vlines = del_vlines(text_width(bufnr), lines, label, "AgentWatchDel1", "AgentWatchDelLabel1")
  local id = vim.api.nvim_buf_set_extmark(bufnr, ns, anchor_row, 0, {
    virt_lines = vlines,
    virt_lines_above = above,
  })
  table.insert(buf_state[bufnr].hunks, {
    type = "del",
    extmark_ids = { id },
    birth = uv.hrtime(),
    lines = lines,
    above = above,
  })
end

local function process_change(bufnr, state, new_lines)
  local old_lines = state.last_lines
  -- vim.diff (xdiff) needs a trailing newline or it misreads the final line
  -- of the input as changed even when it's untouched.
  local old_text = table.concat(old_lines, "\n") .. "\n"
  local new_text = table.concat(new_lines, "\n") .. "\n"
  if old_text == new_text then
    state.last_lines = new_lines
    return
  end

  local hunks = vim.diff(old_text, new_text, { result_type = "indices", algorithm = "myers" })

  -- Apply each hunk as a minimal edit (in reverse so earlier rows stay valid)
  -- instead of set_lines(0, -1): a full-buffer rewrite clobbers every existing
  -- extmark, wiping still-fading highlights from previous changes.
  if hunks then
    for i = #hunks, 1, -1 do
      local start_a, count_a, start_b, count_b = hunks[i][1], hunks[i][2], hunks[i][3], hunks[i][4]
      local repl = {}
      for j = start_b, start_b + count_b - 1 do
        table.insert(repl, new_lines[j])
      end
      local first, last
      if count_a == 0 then
        -- pure insert: xdiff's start_a is the line the insert goes after
        first, last = start_a, start_a
      else
        first, last = start_a - 1, start_a - 1 + count_a
        -- set_lines collapses extmarks in the replaced range onto the edit
        -- point instead of deleting them, stacking stale age labels on the
        -- surviving line — clear them first.
        vim.api.nvim_buf_clear_namespace(bufnr, ns, first, last)
      end
      vim.api.nvim_buf_set_lines(bufnr, first, last, false, repl)
    end
  end
  local new_line_count = #new_lines

  if hunks then
    for _, h in ipairs(hunks) do
      local start_a, count_a, start_b, count_b = h[1], h[2], h[3], h[4]

      if count_b > 0 then
        add_hunk(bufnr, start_b - 1, start_b - 1 + count_b - 1)
      end

      if count_a > 0 then
        local removed = {}
        for i = start_a, start_a + count_a - 1 do
          table.insert(removed, old_lines[i])
        end

        local anchor_row, above
        if count_b > 0 then
          anchor_row = math.max(start_b - 1, 0)
          above = true
        elseif start_b == 0 then
          anchor_row = 0
          above = true
        else
          anchor_row = math.min(start_b - 1, math.max(new_line_count - 1, 0))
          above = false
        end

        del_hunk(bufnr, anchor_row, above, removed)
      end
    end
  end

  state.last_lines = new_lines
end

local function poll_buffer(bufnr, state)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    buf_state[bufnr] = nil
    return
  end

  local mtime = file_mtime_ns(state.path)
  if not mtime or mtime == state.last_mtime then
    return
  end

  if vim.bo[bufnr].modified then
    -- Genuine unsaved user edits: back off WITHOUT advancing last_mtime so the
    -- change is retried on a later poll once the buffer is clean again.
    return
  end

  local ok, new_lines = pcall(vim.fn.readfile, state.path)
  if not ok then
    return
  end

  state.last_mtime = mtime
  process_change(bufnr, state, new_lines)
  -- process_change's nvim_buf_set_lines dirties the buffer, but its content now
  -- matches disk exactly, so clearing 'modified' is accurate — and prevents the
  -- guard above from permanently locking out all future external updates.
  vim.bo[bufnr].modified = false
end

local function poll_all()
  for bufnr, state in pairs(buf_state) do
    poll_buffer(bufnr, state)
  end
end

local function age_bucket(elapsed_sec)
  local bucket = math.floor((elapsed_sec / MAX_AGE_SEC) * AGE_BUCKETS) + 1
  if bucket < 1 then
    bucket = 1
  elseif bucket > AGE_BUCKETS then
    bucket = AGE_BUCKETS
  end
  return bucket
end

local function tick_fade()
  local now = uv.hrtime()
  for bufnr, state in pairs(buf_state) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local kept = {}
      for _, hunk in ipairs(state.hunks) do
        local elapsed = (now - hunk.birth) / 1e9
        if elapsed > MAX_AGE_SEC then
          for _, id in ipairs(hunk.extmark_ids) do
            pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, id)
          end
        else
          local bucket = age_bucket(elapsed)
          local age_str = format_age(elapsed)
          if hunk.type == "add" then
            local hl = "AgentWatchAdd" .. bucket
            local label = { { " +" .. age_str, "AgentWatchAddLabel" .. bucket } }
            for _, id in ipairs(hunk.extmark_ids) do
              local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, id, {})
              local line_count = vim.api.nvim_buf_line_count(bufnr)
              if pos and pos[1] and pos[1] < line_count then
                local row, col = pos[1], pos[2]
                vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
                  id = id,
                  end_row = math.min(row + 1, line_count),
                  end_col = 0,
                  hl_group = hl,
                  hl_eol = true,
                  virt_text = label,
                  virt_text_pos = "right_align",
                })
              end
            end
          else
            local hl = "AgentWatchDel" .. bucket
            local label_hl = "AgentWatchDelLabel" .. bucket
            local id = hunk.extmark_ids[1]
            local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, id, {})
            if pos and pos[1] then
              local row, col = pos[1], pos[2]
              local vlines = del_vlines(text_width(bufnr), hunk.lines, "-" .. age_str .. " ", hl, label_hl)
              vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
                id = id,
                virt_lines = vlines,
                virt_lines_above = hunk.above,
              })
            end
          end
          table.insert(kept, hunk)
        end
      end
      state.hunks = kept
    end
  end
end

local function clear_all()
  for bufnr, _ in pairs(buf_state) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end
  buf_state = {}
end

function M.enable()
  if enabled then
    return
  end
  enabled = true

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      register_buf(bufnr)
    end
  end

  poll_timer = uv.new_timer()
  -- pcall so one failing tick can't kill the timer or spam ENTER prompts
  poll_timer:start(POLL_INTERVAL_MS, POLL_INTERVAL_MS, vim.schedule_wrap(function()
    pcall(poll_all)
  end))

  fade_timer = uv.new_timer()
  fade_timer:start(FADE_INTERVAL_MS, FADE_INTERVAL_MS, vim.schedule_wrap(function()
    pcall(tick_fade)
  end))

  vim.notify("agent-watch: on", vim.log.levels.INFO)
end

function M.disable()
  if not enabled then
    return
  end
  enabled = false

  if poll_timer then
    poll_timer:stop()
    poll_timer:close()
    poll_timer = nil
  end
  if fade_timer then
    fade_timer:stop()
    fade_timer:close()
    fade_timer = nil
  end

  clear_all()
  vim.notify("agent-watch: off", vim.log.levels.INFO)
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.setup()
  define_highlights()

  augroup = vim.api.nvim_create_augroup("AgentWatch", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
    group = augroup,
    callback = function(args)
      if enabled then
        register_buf(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = augroup,
    callback = function(args)
      unregister_buf(args.buf)
    end,
  })

  vim.api.nvim_create_user_command("AgentWatchToggle", function()
    M.toggle()
  end, {})

  -- auto-enable once startup buffers are loaded
  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    callback = function()
      M.enable()
    end,
  })
end

return M
