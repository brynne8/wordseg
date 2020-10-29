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

function string:ulen()
  return select(2, self:gsub('[^\128-\193]', ''))
end

local dict = {}
for line in io.lines('zh-tf.txt') do
  local word, prob = line:match('^(.-)\t([^%s]+)')
  dict[word] = tonumber(prob)
end

--local N = 0
local num = 0

local jieba = {}
for line in io.lines('dict.txt.small') do
  local list = line:split(' ')
  local count = tonumber(list[2])
  --N = N + count
  
  if not list[1]:match('%a') and not dict[list[1]] then
    num = num + 1
    jieba[num] = { word = list[1], count = count }
  end
end
local logN = 7.778888685701

io.output('jieba-tf.txt')
for _, v in ipairs(jieba) do
  io.write(v.word .. '\t' .. (math.log10(v.count) - logN) .. '\n')
end
io.close()
