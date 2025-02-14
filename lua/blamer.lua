-- in blamer.lua
local M = {}
local api = vim.api

local default_emoji="🐛"

local user_emoji=api.nvim_get_var('blamer_emoji')

local used_emoji

-- check if the user has set an emoji and use it for the default log
if user_emoji then
  used_emoji = user_emoji
else
  used_emoji = default_emoji
end

local default_log_format=used_emoji.." %an | %ar | %s"

-- skip scratch buffer or unkown filetype, nvim's terminal window, and other known filetypes need to bypass
local bypass_ft = {'', 'bin', '.', 'vim-plug', 'LuaTree', 'startify', 'nerdtree'}

function M.blameVirtText()
  if vim.bo.buftype ~= '' then
    return
  end

  for _,v in ipairs(bypass_ft) do
    if vim.bo.filetype == v then
      return
    end
  end

  api.nvim_buf_clear_namespace(0, 2, 0, -1) -- clear out virtual text from namespace 2 (the namespace we will set later)
  local currFile = vim.fn.expand('%')
  local line = api.nvim_win_get_cursor(0)
  local blame = vim.fn.system(string.format('git blame -c -L %d,%d %s', line[1], line[1], currFile))
  local hash = vim.split(blame, '%s')[1]
  local cmd = string.format("git show %s ", hash)..string.format("--format='%s'", default_log_format);
  if hash == '00000000' then
    text = 'Not Committed Yet'
  else
    text = vim.fn.system(cmd)
    text = vim.split(text, '\n')[1]
    if text:find("fatal") then -- if the call to git show fails
      text = 'Not Committed Yet'
    end
  end
  api.nvim_buf_set_virtual_text(0, 2, line[1] - 1, {{ text,'GitLens' }}, {}) -- set virtual text for namespace 2 with the content from git and assign it to the higlight group 'GitLens'
end

function M.clearBlameVirtText() -- important for clearing out the text when our cursor moves
  api.nvim_buf_clear_namespace(0, 2, 0, -1)
end

return M
