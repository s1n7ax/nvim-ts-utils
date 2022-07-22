---@diagnostic disable-next-line: undefined-global
local ts = vim.treesitter
local ts_utils = require('nvim-treesitter.ts_utils')
local ts_locals = require('nvim-treesitter.locals')
-- local ts_indent = require('nvim-treesitter.indent')

---@diagnostic disable-next-line: undefined-global
local v = vim
local api = v.api

local M = {}

-- Creates a new instance
-- @param {Object<{
--	    {string} [language] of the parser
-- }>}
function M:new(o)
  o = o or {}

  o.buffer = o.buffer or 0

  setmetatable(o, self)
  self.__index = self
  return o
end

function M:get_parser()
  return ts.get_parser(self.buffer, self.language)
end

function M:refresh()
  self:get_parser():parse()
end

-- Returns the node on the cursor
-- @returns {Node} node on the cursor
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
function M:get_curr_scope()
  return ts_locals.get_scope_tree(self:get_curr_node(), self.buffer)
end

-- Runs the query and return the iterator of matches
-- @param {string} query that should be evaluate
-- @param {Node} [node=Node(Root)] to evaluate the query against
-- @returns {(Query, Iterator<(id, Node, object)>)} iterator of
-- nodes that matched the query
function M:get_matches_iter(queryStr, node)
  if not node then
    node = ts.get_parser(self.buffer, self.language):parse()[1]:root()
  end

  ---@diagnostic disable-next-line: undefined-global
  local query = vim.treesitter.query.parse_query(self.language, queryStr)
  return query, query:iter_matches(node, self.buffer)
end

function M:get_captures_iter(queryStr, node)
  if not node then
    node = ts.get_parser(self.buffer, self.language):parse()[1]:root()
  end

  ---@diagnostic disable-next-line: undefined-global
  local query = vim.treesitter.query.parse_query(self.language, queryStr)
  return query, query:iter_captures(node, self.buffer)
end

function M:get_node_text(node)
  ---@diagnostic disable-next-line: undefined-global
  return vim.treesitter.query.get_node_text(node, self.buffer)
end

return M
