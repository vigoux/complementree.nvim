local filters = require 'complementree.filters'
local utils = require 'complementree.utils'
require 'busted.runner' { output = 'TAP', shuffle = true }

local function mk_compl_element(word)
  return {
    word = word,
    kind = 'mock',
  }
end

local function run(source, line, cursor)
  local res, _ = source(line, 0)
  local ret = {}
  for _, r in pairs(res) do
    table.insert(ret, utils.cword(r))
  end

  return ret
end

describe('filter', function()
  local mock_source

  before_each(function()
    mock_source = spy.new(function(line)
      local pref_start = line:find '%S*$'
      local prefix = line:sub(pref_start)
      return {
        mk_compl_element 'foo',
        mk_compl_element 'foobar',
        mk_compl_element 'foobaz',
        mk_compl_element 'barbaz',
        mk_compl_element 'baz',
      }, prefix
    end)
  end)

  describe('prefix', function()
    it('works', function()
      local f = filters.prefix(mock_source)
      local res = run(f, '')
      assert.are.same(res, { 'foo', 'foobar', 'foobaz', 'barbaz', 'baz' })
      assert.spy(mock_source).was.called(1)
    end)

    it('filters correctly', function()
      local f = filters.prefix(mock_source)
      local res = run(f, 'fo')
      assert.are.same(res, { 'foo', 'foobar', 'foobaz' })

      local res = run(f, 'bar')
      assert.are.same(res, { 'barbaz' })
      assert.spy(mock_source).was.called(2)
    end)

    it('does not error on empty', function()
      local f = filters.prefix(function()
        return {}
      end)
      local res = run(f, '')
      assert.are.same(res, {})
    end)

    it('matches completely', function()
      local f = filters.prefix(mock_source)
      local res = run(f, 'foobar')
      assert.are.same(res, { 'foobar' })
    end)
  end)

  describe('strict_prefix', function()
    it('works', function()
      local f = filters.strict_prefix(mock_source)
      local res = run(f, '')

      assert.are.same(res, { 'foo', 'foobar', 'foobaz', 'barbaz', 'baz' })
      assert.spy(mock_source).was.called(1)
    end)

    it('filters correctly', function()
      local f = filters.strict_prefix(mock_source)
      local res = run(f, 'fo')
      assert.are.same(res, { 'foo', 'foobar', 'foobaz' })

      local res = run(f, 'bar')
      assert.are.same(res, { 'barbaz' })
      assert.spy(mock_source).was.called(2)
    end)

    it('does not error on empty', function()
      local f = filters.strict_prefix(function()
        return {}
      end)
      local res = run(f, '')
      assert.are.same(res, {})
    end)

    it('does not match completely', function()
      local f = filters.strict_prefix(mock_source)
      local res = run(f, 'foobar')
      assert.are.same(res, {})

      local res = run(f, 'foo')
      assert.are.same(res, { 'foobar', 'foobaz' })
    end)
  end)

  describe('amount', function()
    it('works', function()
      local f = filters.amount(2)(mock_source)
      local res = run(f, '')
      assert.are.same(res, { 'foo', 'foobar' })
    end)

    it('handles 0', function()
      local f = filters.amount(0)(mock_source)
      local res = run(f, '')
      assert.are.same(res, {})
    end)

    it('handles empty matches', function()
      local f = filters.amount(2)(function()
        return {}
      end)
      local res = run(f, '')
      assert.are.same(res, {})
    end)
  end)
end)
