require 'torch'
local vocab = dofile('vocab.lua')

local dir = arg[1]
local t=tonumber(arg[2])
local biphr = arg[3]
local phr = arg[4]
paths.mkdir(dir..'/proba')

local phrase = vocab(dir .. '/vocab/'..phr..'.txt', t)
local biphrase = vocab(dir .. '/vocab/'..biphr..'_ge'..t..'.txt', 1)
local phrasesz = phrase:size()
local biphrasesz = biphrase:size()

local count=torch.FloatTensor(biphrasesz,phrasesz):zero()
-- load training sentences
local setsz={}
for line in io.lines(dir..'/nb.txt') do
  table.insert(setsz,tonumber(line))
end
print('# of images = '..#setsz)
local fsent = io.open(dir..'/sentences.final','r')
local fchk = io.open(dir..'/sentences.chkszfinal','r')
-- loop over training images
for i=1,#setsz do
  for k=1,setsz[i] do
    local sentline=fsent:read()
    local chkline=fchk:read()
    local chunk={}
    for sz,ph in chkline:gmatch('(%d+)%-(%S+)') do
      table.insert(chunk,{ph=ph,sz=sz})
    end
    local sent={}
    for word in sentline:gmatch('%S+') do
      table.insert(sent,word)
    end

    local sz = #chunk -- get current size
    if sz>3 then
      local itr=1
      for k=1,(sz-3) do -- last chunk is always PERIOD (i.e. 1-O)
        -- concat words
        local cond = chunk[k].ph .. "-" .. chunk[k+1].ph
        if cond == biphr and chunk[k+2].ph == phr then
          local c1 = chunk[k]
          local c2 = chunk[k+1]
          local c3 = chunk[k+2]
          local chk1 = table.concat(sent, ' ', itr, itr+c1.sz+c2.sz-1)
          local chk2 = table.concat(sent, ' ', itr+c1.sz+c2.sz, itr+c1.sz+c2.sz+c3.sz-1)

          local idx1 = biphrase:get(chk1)
          local idx2 = phrase:get(chk2)
          if idx1>0 and idx2>0 then
            count[idx1][idx2] = count[idx1][idx2]+1
          end
        end
        itr=itr+chunk[k].sz
      end
    end
  end
end
-- closing files
fsent:close()
fchk:close()

-- get probabilities
for i=1,biphrasesz do
  count[i]:div(count[i]:sum())
end

local fout=io.open(dir..'/proba/'..phr..'_given_'..biphr..'_ge'..t..'.proba','w')
for i=1,biphrasesz do
  for j=1,phrasesz do
    if count[i][j]>0 then
      fout:write(biphrase[i] .. '\t' .. phrase[j] .. '\t' .. count[i][j].. '\n')
    end
  end
end
fout:close()
