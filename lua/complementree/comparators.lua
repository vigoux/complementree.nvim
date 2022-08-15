local utils = require('complementree.utils')

local Comparators = {}






local Comparator = {}

local function mk_comparator(func)
   return function(msource)
      return function(ltc, lnum)
         local orig, prefix = msource(ltc, lnum)
         local cmp_cache = {}
         table.sort(orig, function(a, b)
            local key = { a, b }

            if not cmp_cache[key] then
               cmp_cache[key] = func(utils.cword(a), utils.cword(b))
            end

            return cmp_cache[key]
         end)
         return orig, prefix
      end
   end
end

Comparators.alphabetic = mk_comparator(function(a, b)
   return a < b
end)

Comparators.length = mk_comparator(function(a, b)
   return #a < #b
end)

local ok_fzy, fzy = pcall(require, 'fzy-lua-native')
if ok_fzy then
   local function mk_fzy(is_case_sensitive)
      return function(msource)
         return function(ltc, lnum)
            local orig, prefix = msource(ltc, lnum)
            local scores = {}
            local matching = {}
            if prefix ~= "" then
               for _, a in ipairs(orig) do
                  local s = fzy.score(prefix, utils.cword(a), is_case_sensitive)
                  if math.abs(s) ~= math.huge or prefix == utils.cword(a) then
                     scores[a] = s
                     table.insert(matching, a)
                  end
               end
               table.sort(matching, function(a, b)
                  return scores[a] > scores[b]
               end)
               return matching, prefix
            else
               return orig, prefix
            end
         end
      end
   end
   Comparators.fzy = mk_fzy(false)
   Comparators.ifzy = mk_fzy(true)
end

return Comparators
