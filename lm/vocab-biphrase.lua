local dir = arg[1]
local t=tonumber(arg[2])

local function vocab(phrase1, phrase2)
  local vocab={}
  for line in io.lines(dir .. '/text/image_'..phrase1.."-"..phrase2..'_ge'..t..'.txt') do
    local _,phr1,phr2 = line:match('(%d+)\t(.+)\t(.*)')
    local key = phr1 .. ' ' .. phr2
    if vocab[key] == nil then
      table.insert(vocab,key)
      vocab[key] = 1
    else
      vocab[key] = vocab[key] + 1
    end
  end
  table.sort(vocab,function(a,b) return vocab[a]>vocab[b] end)
  local fout=io.open(dir..'/vocab/'..phrase1..'-'..phrase2..'_ge'..t..'.txt','w')
  for i,v in ipairs(vocab) do
    fout:write(v .. '\t' .. vocab[v] .. '\n')
  end
  fout:close()
end

vocab('NP','PP')
vocab('NP','VP')
vocab('PP','NP')
vocab('VP','NP')
