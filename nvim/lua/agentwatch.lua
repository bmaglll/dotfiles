-- agentwatch: poll watched buffers for on-disk changes (e.g. from a coding
-- agent editing files externally) and highlight recent edits with a fading
-- diff-style gradient. Toggle globally with :AgentWatchToggle.

local uv = vim.uv or vim.loop

local M = {}

local POLL_INTERVAL_MS = 500
local FADE_INTERVAL_MS = 1000
local MAX_AGE_SEC = 120
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
  end
  for i, c in ipairs(DEL_COLORS) do
    vim.api.nvim_set_hl(0, "AgentWatchDel" .. i, { bg = c })
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

local function add_hunk(bufnr, row_start, row_end)
  local ids = {}
  for row = row_start, row_end do
    local id = vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
      end_row = row + 1,
      end_col = 0,
      hl_group = "AgentWatchAdd1",
      hl_eol = true,
    })
    table.insert(ids, id)
  end
  table.insert(buf_state[bufnr].hunks, {
    type = "add",
    extmark_ids = ids,
    birth = uv.hrtime(),
  })
end

local function del_hunk(bufnr, anchor_row, above, lines)
  local vlines = {}
  for _, line in ipairs(lines) do
    table.insert(vlines, { { line, "AgentWatchDel1" } })
  end
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
  local old_text = table.concat(old_lines, "\n")
  local new_text = table.concat(new_lines, "\n")
  if old_text == new_text then
    state.last_lines = new_lines
    return
  end

  local hunks = vim.diff(old_text, new_text, { result_type = "indices", algorithm = "myers" })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
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
  state.last_mtime = mtime

  if vim.bo[bufnr].modified then
    -- Don't clobber unsaved edits in the buffer; try again next poll.
    return
  end

  local ok, new_lines = pcall(vim.fn.readfile, state.path)
  if not ok then
    return
  end

  process_change(bufnr, state, new_lines)
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
          local hl = (hunk.type == "add" and "AgentWatchAdd" or "AgentWatchDel") .. bucket
          for _, id in ipairs(hunk.extmark_ids) do
            local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, id, {})
            if pos and pos[1] then
              local row, col = pos[1], pos[2]
              if hunk.type == "add" then
                vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
                  id = id,
                  end_row = row + 1,
                  end_col = 0,
                  hl_group = hl,
                  hl_eol = true,
                })
              else
                local vlines = {}
                for _, line in ipairs(hunk.lines) do
                  table.insert(vlines, { { line, hl } })
                end
                vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
                  id = id,
                  virt_lines = vlines,
                  virt_lines_above = hunk.above,
                })
              end
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
  poll_timer:start(POLL_INTERVAL_MS, POLL_INTERVAL_MS, vim.schedule_wrap(poll_all))

  fade_timer = uv.new_timer()
  fade_timer:start(FADE_INTERVAL_MS, FADE_INTERVAL_MS, vim.schedule_wrap(tick_fade))

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
end

return M
