require 'torch'
local vocab = dofile('vocab.lua')

local dir = arg[1]
local t=tonumber(arg[2])
paths.mkdir(dir..'/proba')

local NP = vocab(dir .. '/vocab/NP.txt', t) -- load NP
local VP = vocab(dir .. '/vocab/VP.txt', t) -- load VP
local PP = vocab(dir .. '/vocab/PP.txt', t) -- load PP
-- get number of NP
local NPsz = NP:size()

-- P (NP | START)
local count=torch.Tensor(NPsz):zero()
for line in io.lines(dir..'/text/image_START-NP_ge'..t..'.txt') do
  local np = line:match('%d+\t(.*)')
  local idx = NP:get(np)
  count[idx] = count[idx]+1
end
local total = count:sum()
count:div(total)
local fout = io.open(dir..'/proba/NP_given_START_ge'..t..'.proba','w')
for i=1,NPsz do
  fout:write(NP[i] .. '\t' ..count[i] .. '\n')
end
fout:close()

local function transition_proba(phrase1, vocab1, phrase2, vocab2)
  local vocab1sz = vocab1:size()
  local vocab2sz = vocab2:size()
  local count=torch.FloatTensor(vocab1sz,vocab2sz):zero()
  for line in io.lines(dir..'/text/image_'..phrase1..'-'..phrase2..'_ge'..t..'.txt') do
    local chk1,chk2 = line:match('%d+\t(.+)\t(.*)')
    local idx1 = vocab1:get(chk1)
    local idx2 = vocab2:get(chk2)
    count[idx1][idx2] = count[idx1][idx2]+1
  end
  for i=1,vocab1sz do
    count[i]:div(count[i]:sum())
  end

  local fout = io.open(dir..'/proba/'..phrase2..'_given_'..phrase1..'_ge'..t..'.proba','w')
  for i=1,vocab1sz do
    for j=1,vocab2sz do
      if count[i][j]>0 then
        fout:write(vocab1[i] .. '\t' .. vocab2[j] .. '\t' .. count[i][j].. '\n')
      end
    end
  end
  fout:close()
end
-- P(PP | NP)
transition_proba('NP',NP,'PP',PP)
-- P(VP | NP)
transition_proba('NP',NP,'VP',VP)
-- P(NP | PP)
transition_proba('PP',PP,'NP',NP)
-- P(NP | VP)
transition_proba('VP',VP,'NP',NP)

-- P ( . | NP)
local count=torch.Tensor(NPsz,3):zero()
local function transition_after_np(phrase, i)
  for line in io.lines(dir..'/text/image_NP-'..phrase..'_ge'..t..'.txt') do
    local np
    if phrase == 'PERIOD' then
      np = line:match('%d+\t(.*)')
    else
      np = line:match('%d+\t(.+)\t.*')
    end
    local idx = NP:get(np)
    count[idx][i] = count[idx][i]+1
  end
end
transition_after_np('VP',1)
transition_after_np('PP',2)
transition_after_np('PERIOD',3)
for i=1,NPsz do
  count[i]:div(count[i]:sum())
end
fout = io.open(dir..'/proba/CHK_given_NP_ge'..t..'.proba','w')
for i=1,NPsz do
  fout:write(NP[i] .. '\t' ..count[i][1].. '\t' ..count[i][2].. '\t' ..count[i][3] .. '\n')
end
fout:close()
