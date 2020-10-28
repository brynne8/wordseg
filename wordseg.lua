local f = io.open('covid19.txt', 'rb')
local text = f:read('*all')
f:close()

local re = require('lpeg.re')

local corpus = re.compile([[
  article <- {| (punct / {sentence})+ |}
  sentence <- ([^]] .. '\226\227\239' .. [[]+ / !punct .)+
  punct <- '，'/'。'/'《'/'》'/'、'/'？'/'：'/'；'/'“'/'”'/'‘'
            /'’'/'｛'/'｝'/'【'/'】'/'（'/'）'/'…'/'￥'/'！'
]])

function string:ulen()
  return select(2, self:gsub('[^\128-\193]', ''))
end

local logN = 10.032024358385
local dict = {}
for line in io.lines('zh-tf.txt') do
  local word, prob = line:match('^(.-)\t([^%s]+)')
  dict[word] = tonumber(prob)
end

local cache = {}

function wordseg(input, maxlen)
  -- memoization: check wheather input has already calculated,
  -- if yes then return from cache
  local best_comp = cache[input]
  local cached_seg, cached_prob
  if best_comp then return best_comp
  else cached_seg, cached_prob = '', -math.huge end
  
  local input_len = input:ulen()
  local i = 0
  local part1 = ''
  
  local has_kanji = false
  local defs = {}
  
  defs.western = function(s, char, e)
    --print('western', s, char, e)
    i = i + e - s
    if i == input_len then
      cached_seg, cached_prob = char, 0
    else
      local seg, prob_log_sum = unpack(wordseg(input:sub(e), maxlen))
      cached_seg, cached_prob = char .. ' ' .. seg, prob_log_sum
    end
  end
  
  defs.kanji = function(char, pos)
    --print('kanji', char, pos)
    part1 = part1 .. char
    i = i + 1
    -- logarithmic probability of part1
    local prob_log_part1 = dict[part1]
    if not prob_log_part1 then
      prob_log_part1 = 3 * (1 - i) - logN
    end
    
    local seg, prob_log_sum = '', 0
    if i < input_len then
      seg, prob_log_sum = unpack(wordseg(input:sub(pos), maxlen))
    end
    
    if i == 1 or prob_log_part1 + prob_log_sum > cached_prob then
      if i == input_len then
        cached_seg, cached_prob = part1, prob_log_part1
      else
        cached_seg, cached_prob = part1 .. ' ' .. seg, prob_log_part1 + prob_log_sum
      end
    end
  end
  
  local segment_it = re.compile([[
    sentence <- alnum+ / utf8^-]] .. maxlen .. [[
    alnum    <- ({} {[%s%w.,/-]+} {}) -> western ]] ..
    "utf8    <- ({[\0-\127\194-\244][\128-\191]*} {}) -> kanji", defs)
  
  segment_it:match(input)
  
  best_comp = { cached_seg, cached_prob }
  cache[input] = best_comp
  return best_comp
end

--local res = corpus:match(text)
--
--for i, v in ipairs(res) do
--  print(unpack(wordseg(v, 5)))
--end

print(unpack(wordseg('新冠病毒', 5)))
