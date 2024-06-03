local Treesitter = require('ts-utils.treesitter')

local M = Treesitter:new({ language = 'typescript', buffer = 0 })

function M:has_react_import()
  self:refresh()
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

function M:get_component_name()
  self:refresh()
  local root = self:get_root_node()

  local query = [[
  ((export_statement 
    declaration: (function_declaration
      name: (identifier) @component_name)) 
    @export_statement (#match? @export_statement "^export default"))
  ]]

  local q, iter = self:get_captures_iter(query, root)

  local component_name

  for id, node in iter do
    local name = q.captures[id]
    if name == 'component_name' then
      component_name = self:get_node_text(node)
    end
  end

  return component_name
end

function M:component_prop_range()
  self:refresh()
  local root = self:get_root_node()

  local query = [[
  ((export_statement 
    declaration: (function_declaration
      parameters: (formal_parameters) @params))
    @export_statement (#match? @export_statement "^export default"))
  ]]

  local q, iter = self:get_captures_iter(query, root)

  local param_node

  for id, node in iter do
    local name = q.captures[id]
    if name == 'params' then
      param_node = node
    end
  end

  return param_node:range()
end

return M
