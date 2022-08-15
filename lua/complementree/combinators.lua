local M = {}

local function complete(col, matches)
   if matches and #matches > 0 then
      vim.fn.complete(col, matches)
      return true
   else
      return false
   end
end

function M.combine(...)
   local funcs = { ... }
   return function(ltc, lnum)
      local matches = {}
      local coherent_p
      for _, f in ipairs(funcs) do
         local m, p = f(ltc, lnum)
         if not coherent_p then
            coherent_p = p
         end

         if coherent_p == p then
            vim.list_extend(matches, m)
         end
      end
      return matches, coherent_p
   end
end

function M.optional(mandat, opt)
   return function(ltc, lnum)
      local matches, prefix = mandat(ltc, lnum)
      if #matches > 0 then
         local m, p = opt(ltc, lnum)
         if p == prefix then
            vim.list_extend(matches, m)
         end
         return matches, prefix
      else
         return {}, ''
      end
   end
end


function M.non_empty_prefix(func)
   return function(ltc, lnum)
      local compl, prefix = func(ltc, lnum)
      if #prefix > 1 then
         return complete(#ltc - #prefix + 1, compl)
      else
         return false
      end
   end
end

function M.wrap(func)
   return function(ltc, lnum)
      local compl, prefix = func(ltc, lnum)
      return complete(#ltc - #prefix + 1, compl)
   end
end

function M.pipeline(source, ...)
   local current = source
   for _, func in ipairs({ ... }) do
      current = func(current)
   end

   return M.wrap(current)
end

function M.chain(...)
   local funcs = { ... }
   return function(ltc, lnum)
      for _, f in ipairs(funcs) do
         local c, pref = f(ltc, lnum)
         if #c > 0 then
            return c, pref
         end
      end
      return {}, ''
   end
end

return M
