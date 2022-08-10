local Helper = require('ts-utils.helper')

local queries = {
  container_function = [[
	[
	  (function_definition
		parameters: (parameters) @parameters
        body: (block) @body)

	  (function_definition
		parameters: (parameters) @parameters)

  	  (function_declaration
  	    name: (method_index_expression
  	  	  table: (identifier) @instance
  	  	  method: (identifier) @name)
  	    parameters: (parameters) @parameters
  	    body: (block) @body)

  	  (function_declaration
  	    name: (identifier) @name
  	    parameters: (parameters) @parameters
  	    body: (block) @body)
  
	  (function_declaration
		name: (identifier) @name
		parameters: (parameters) @parameters)

	  (variable_declaration
		(assignment_statement
		  (variable_list
			name: (identifier) @name)
		(expression_list
		  (function_definition
			parameters: (parameters) @parameters
			body: (block) @body))))

	  (variable_declaration
		(assignment_statement
		  (variable_list
			name: (identifier) @name)
		(expression_list
		  (function_definition
			parameters: (parameters) @parameters))))
	]
	]],
}

local M = Helper:new({ language = 'lua', buffer = 0 })

-- Returns the node of the function in which the current
-- node contained
-- @returns {Node | nil} function node if exists
function M:get_curr_container_func()
  local scope = self:get_curr_scope()

  for _, node in ipairs(scope) do
    if
      node:type() == 'function_declaration'
      or node:type() == 'function_definition'
    then
      return node
    end
  end
end

-- Returns the function information of the function in which
-- the current node contained
-- @returns {{
--		{string} name of the function
--		{Array<{
--		  name: string
--		}>} parameters
--		{Array<any>} return value
-- }}
function M:get_curr_container_func_info()
  local func_node = self:get_curr_container_func()

  if not func_node then
    return
  end

  local query, matches = self:get_matches_iter(
    queries.container_function,
    func_node
  )

  local match = ({ matches() })[2]
  local info = {}

  if not match then
    return
  end

  for id, node in pairs(match) do
    local capture_name = query.captures[id]

    if capture_name == 'instance' then
      info.instance = self:get_node_text(node)
    elseif capture_name == 'name' then
      info.name = self:get_node_text(node)
    elseif capture_name == 'parameters' then
      info.parameters = self:get_param_info_from_parameters(node)
    elseif capture_name == 'body' then
      info.returns = self:get_return_info_from_body(node)
    end
  end

  return info
end

function M:get_param_info_from_parameters(parameters_node)
  local info = {}

  for param in parameters_node:iter_children() do
    if param:type() == 'identifier' then
      table.insert(info, {
        name = self:get_node_text(param),
      })
    end
  end

  return info
end

function M:get_return_nodes_from_body(body_node)
  local return_nodes = {}
  local function find_return_statements(node)
    -- if there is an inner function the stop the find
    if
      node:type() == 'function_declaration'
      or node:type() == 'function_definition'
    then
      return
    end

    if node:type() == 'return_statement' then
      table.insert(return_nodes, node)
      return
    end

    for child in node:iter_children() do
      find_return_statements(child)
    end
  end

  find_return_statements(body_node)

  return return_nodes
end

function M:get_return_info_from_body(body_node)
  local info = {}
  local return_nodes = self:get_return_nodes_from_body(body_node)

  for _, return_node in ipairs(return_nodes) do
    local return_info = {}

    for expression_list in return_node:iter_children() do
      for expr in expression_list:iter_children() do
        local return_type = expr:type()

        if return_type == 'table_constructor' then
          table.insert(return_info, 'table')
        elseif return_type == 'string' or return_type == 'number' then
          table.insert(return_info, return_type)
        elseif return_type == 'false' or return_type == 'true' then
          table.insert(return_info, 'boolean')
        else
          if expr:named() then
            table.insert(return_info, 'any')
          end
        end
      end
    end

    table.insert(info, return_info)
  end

  return info
end

return M
