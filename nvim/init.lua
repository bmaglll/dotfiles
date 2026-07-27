
-- Use the system clipboard for all yanks / deletes / puts
vim.opt.clipboard = "unnamedplus"

-- Line numbers
vim.opt.number = true

-- Live diff highlighting for files edited externally (e.g. by a coding agent)
require("agentwatch").setup()

