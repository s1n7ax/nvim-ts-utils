---@diagnostic disable-next-line: undefined-global
local ts = vim.treesitter
local ts_utils = require('nvim-treesitter.ts_utils')
local ts_locals = require('nvim-treesitter.locals')
-- local ts_indent = require('nvim-treesitter.indent')

-- @diagnostic disable-next-line: undefined-global
-- local v = vim
-- local api = v.api

local M = {}

-- Creates a new instance
-- @param o table {{
--  {string} language of the parser
--  {buffer} buffer to refer. DEFAULT = 0
-- }}
-- @return table class instance
function M:new(o)
  o = o or {}

  o.buffer = o.buffer or 0

  setmetatable(o, self)
  self.__index = self
  return o
end

-- Returns the parser
-- @return table
-- @see {@link lua-treesitter-parser| https://neovim.io/doc/user/treesitter.html#lua-treesitter-parser}
function M:get_parser()
  return ts.get_parser(self.buffer, self.language)
end

-- Refresh the syntax tree
function M:refresh()
  self:get_parser():parse()
end

-- Returns the node on the cursor
-- @returns {Node}
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_curr_node()
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
  return ts_locals.get_scope_tree(self:get_curr_node(), self.buffer)
end

-- Runs the query and return the iterator of matches
-- @param {string} query that should be evaluate
-- @param {Node} [node=Node(Root)] to evaluate the query against
-- @returns {(Query, Iterator<(id, Node, object)>)} iterator of
-- nodes that matched the query
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_matches_iter(queryStr, node)
  if not node then
    node = ts.get_parser(self.buffer, self.language):parse()[1]:root()
  end

  ---@diagnostic disable-next-line: undefined-global
  local query = vim.treesitter.query.parse_query(self.language, queryStr)
  return query, query:iter_matches(node, self.buffer)
end

-- Runs the query and return the iterator of captures
-- @param {string} queryStr that should be evaluate
-- @param {Node} [node=Node(Root)] to evaluate the query against
-- @returns {(Query, Iterator<(id, Node, object)>)} iterator of nodes that matched the query
-- @see {@link lua-treesitter-node| https://neovim.io/doc/user/treesitter.html#lua-treesitter-node} node on the cursor
function M:get_captures_iter(queryStr, node)
  if not node then
    node = ts.get_parser(self.buffer, self.language):parse()[1]:root()
  end

  ---@diagnostic disable-next-line: undefined-global
  local query = vim.treesitter.query.parse_query(self.language, queryStr)
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

return M
