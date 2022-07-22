local Lua = require('ts-utils.lua')
local Helper = require('ts-utils.helper')

local M = {}

function M.run()
  local a = Lua:new()
  Log.ins(a:get_curr_container_func_info())
end

return M
