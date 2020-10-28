function string.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = '(.-)' .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= '' then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

local N = 0
for line in io.lines('zh-total') do
  local list = line:split('\t')
  for i = 2, #list do
    local year, num = list[i]:match('^(%d+),(%d+)')
    if num and tonumber(year) > 1919 then
      N = N + tonumber(num)
    end
  end
end
local logN = math.log10(N)
print(logN)

local tf = {}
local tf_count = 0
do
  local tf_dict = {}
  for line in io.lines('zh-50k') do
    local list = line:split('\t')
    local word, class = list[1]:match('^([^_%s]+)_?([^%s]*)')
    if word and not word:match('^[%d%a%p]+$') then
      local count = 0
      for i = 2, #list do
        local year, num = list[i]:match('^(%d+),(%d+)')
        if num and tonumber(year) > 1919 then
          count = count + tonumber(num)
        end
      end
      local val = tf_dict[word]
      if val then tf_dict[word] = val + count
      else tf_dict[word] = count end
    end
  end
  
  for k, v in pairs(tf_dict) do
    tf_count = tf_count + 1
    tf[tf_count] = { word = k, count = v }
  end
end

io.output('zh-tf.txt')
for _, v in ipairs(tf) do
  io.write(v.word .. '\t' .. (math.log10(v.count) - logN) .. '\n')
end
io.close()
