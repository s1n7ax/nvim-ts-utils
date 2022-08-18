local JS = require('ts-utils.javascript')
local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

function M.run()
  ---@diagnostic disable-next-line: undefined-global
  local row, column = table.unpack(vim.api.nvim_win_get_cursor(0))

  row = row - 1

  print('>>>>>')
  print(row, column)

  local a = JS:new()
  local scope = a:get_scope_at_pos(row, column)

  for _, value in ipairs(scope) do
    print(value:type())
  end
  -- local parser = a:get_parser()
  -- local syntax_tree = parser:parse()
  -- print(node:type())

  -- local root = syntax_tree[1]:root()

  -- local v = (root)

  -- -- print(v)

  -- if v then
    -- v:type()
  -- end
end

return M
