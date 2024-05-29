---@diagnostic disable-next-line: undefined-global
local ts = vim.treesitter
local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

-- Creates a new instance
-- @param o table {{
--  {string} language of the parser
--  {buffer} buffer to refer. DEFAULT = 0
-- }}
-- @returns table class instance
function M:new(o)
  o = o or {}

  assert(o.language or self.language, 'language should be passed to the class')

  o.buffer = o.buffer or self.buffer or 0

  setmetatable(o, self)
  self.__index = self
  return o
end

-- Returns the parser
-- @returns {Parser}
-- @see {@link lua-treesitter-parser| https://neovim.io/doc/user/treesitter.html#lua-treesitter-parser}
function M:get_parser()
  return ts.get_parser(self.buffer, self.language)
end

-- Refresh the syntax tree
function M:refresh()
  self:get_parser():parse()
end

-- Refresh the syntax tree and returns the syntax tree
-- @returns {Array<Tree>}
-- @see {@link lua-treesitter-tree| https://neovim.io/doc/user/treesitter.html#lua-treesitter-tree}
function M:get_syntax_trees()
  return self:get_parser():parse()
end

-- Returns the root node of the first syntax tree
-- @returns {Node}
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_root_node()
  return self:get_syntax_trees()[1]:root()
end

-- Returns the deepest node that contains the given position
-- @param {number} line of the position
-- @param {number} column nth character in the line
-- @returns {Node}
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_node_at_pos(line, column)
  local scope = self:get_scope_at_pos(line, column)

  if #scope == 0 then
    return
  end

  return scope[1]
end

-- Returns list of nodes that is in between node at the given position and the root node
-- In following node tree, if the node at position is "D" then the scope would
-- return [Node(D), Node(B), Node(R)]
--      ┌─────┐
--    ┌─┤  R  ├─┐
--    │ └─────┘ │
--    │         │
-- ┌──┴──┐   ┌──┴──┐
-- │  A  │ ┌─┤  B  ├─┐
-- └─────┘ │ └─────┘ │
--         │         │
--         │         │
--      ┌──┴──┐   ┌──┴──┐
--      │  C  │   │  D  │
--      └─────┘   └─────┘
--
-- @returns {Array<Node>} list of nodes
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_scope_at_pos(row, column)
  local root = self:get_root_node()
  local get_scope = self:__get_scope_at_pos_finder(row, column)

  return get_scope(root)
end

-- Runs the query and return the iterator of matches
-- @param {string} query that should be evaluate
-- @param {Node} [node=Node(Root)] to evaluate the query against
-- @returns {(Query, Iterator<(id, Node, object)>)} iterator of
-- nodes that matched the query
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_matches_iter(query_str, node)
  if not node then
    node = ts.get_parser(self.buffer, self.language):parse()[1]:root()
  end

  ---@diagnostic disable-next-line: undefined-global
  local query = vim.treesitter.query.parse(self.language, query_str)
  return query, query:iter_matches(node, self.buffer)
end

-- Runs the query and return the iterator of captures
-- @param {string} queryStr that should be evaluate
-- @param {Node} [node=Node(Root)] to evaluate the query against
-- @returns {(Query, Iterator<(id, Node, object)>)} iterator of nodes that matched the query
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_captures_iter(query_str, node)
  if not node then
    node = ts.get_parser(self.buffer, self.language):parse()[1]:root()
  end

  ---@diagnostic disable-next-line: undefined-global
  local query = vim.treesitter.query.parse_query(self.language, query_str)
  return query, query:iter_captures(node, self.buffer)
end

-- Returns the node text
-- @param {Node} to get the text of
-- @returns {string} text of the node
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_node_text(node)
  ---@diagnostic disable-next-line: undefined-global
  return vim.treesitter.query.get_node_text(node, self.buffer)
end

-- Returns the node on the cursor
-- @returns {Node}
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_curr_node()
  self:get_parser():parse()
  return ts_utils.get_node_at_cursor()
end

-- Returns list of nodes that is in between node on the cursor and the root node
-- In following node tree, if the current node is "D" then the scope would
-- return [Node(D), Node(B), Node(R)]
--      ┌─────┐
--    ┌─┤  R  ├─┐
--    │ └─────┘ │
--    │         │
-- ┌──┴──┐   ┌──┴──┐
-- │  A  │ ┌─┤  B  ├─┐
-- └─────┘ │ └─────┘ │
--         │         │
--         │         │
--      ┌──┴──┐   ┌──┴──┐
--      │  C  │   │  D  │
--      └─────┘   └─────┘
--
-- @returns {Array<Node>} list of nodes
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_curr_scope()
  local curr_node = self:get_curr_node()

  local scope = {}

  if not curr_node then
    return scope
  end

  repeat
    table.insert(scope, curr_node)
    curr_node = curr_node:parent()
  until not curr_node

  return scope
end

function M:__get_scope_at_pos_finder(row, column)
  local scope = {}

  local function find(root)
    for node in root:iter_children() do
      local sraw, scolumn = node:start()
      local eraw, ecolumn = node:end_()

      if row >= sraw and row <= eraw then
        if
          (row > sraw and row < eraw)
          or (row > sraw and column <= ecolumn)
          or (row < eraw and column >= scolumn)
          or (
            (row == sraw or row == eraw)
            and column >= scolumn
            and column <= ecolumn
          )
        then
          table.insert(scope, find(node))
        end
      end
    end

    return root
  end

  return function(root)
    find(root)
    return scope
  end
end

return M
