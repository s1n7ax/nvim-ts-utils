local Treesitter = require('ts-utils.treesitter')

local M = Treesitter:new({ language = 'typescript', buffer = 0 })

function M:has_react_import()
  local root = self:get_root_node()

  local query = [[
  (import_statement 
    (import_clause) @import_name (#eq? @import_name "React")
    source: (string (string_fragment) @import_source (#eq? @import_source "react")  ))
  ]]

  local _, iter = self:get_matches_iter(query, root)

  if select(1, iter()) then
    return true
  else
    return false
  end
end

return M
