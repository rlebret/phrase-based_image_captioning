require 'torch'

cmd = torch.CmdLine()
cmd:text()
cmd:text('Computing phrase embeddings from word embeddings')
cmd:text()
cmd:text()
cmd:text('Misc options:')
cmd:option('-emb', '', 'files with word embeddings (a 2D torch.FloatTensor)')
cmd:option('-vocab', '', 'vocabulary of word embeddings (a word per line)')
cmd:option('-phr', '', 'phrase type {NP,VP,PP}')
cmd:option('-pfsz', 400, 'phrase embeddings size')
cmd:option('-t', 10, 'phrase appearance frequency')
cmd:option('-dir', '', 'where to find and save data')
cmd:text()
cmd:text()
local params = cmd:parse(arg)

--------------------------------------------------------------------------------
-- Loading word emebddings
--------------------------------------------------------------------------------
-- load vocabulary (a word per line)
local words={}
local vocabsz = 0
for line in io.lines(params.vocab) do
  vocabsz = vocabsz+1
  words[line]=vocabsz
end
print("# of word embeddings = "..vocabsz)
print('loading word embeddings...')
---- load embeddings which are in a torch.FloatTensor(nword, dim)
local femb = torch.DiskFile(params.emb, 'r'):binary()
local emb = femb:readObject()
femb:close()
-- get size
local wfsz = emb:size(2)
if wfsz < params.pfsz then
  error('word embeddings dimension (=' .. wfsz .. ') is too small')
end
local lookup = emb:narrow(2, 1, params.pfsz) -- get the required dimension
local mean=lookup:mean()
local std=lookup:std()
print('--> mean = '..mean)
print('--> std = '..std)

--------------------------------------------------------------------------------
-- Loading phrases
--------------------------------------------------------------------------------
-- get phrase from vocabulary
local phrases={}
local maxsz=0
for line in io.lines(params.dir..'/vocab/'..params.phr..'.txt') do
  local ph,fq=line:match('(.-)\t(%d+)')
  fq=tonumber(fq)
  if fq<params.t then break end
  local t={}
  for w in ph:gmatch('%S+') do
    if words[w] ~= nil then
      table.insert(t,words[w])
    end
  end
  if #t>maxsz then maxsz=#t end
  table.insert(phrases,torch.LongTensor(t))
end
local nphrases = #phrases
print('# of '..params.phr..' = '.. nphrases)
print('--> maximum length = '..maxsz)

-- create output directory
local outdir = params.dir .. '/lookup/'
os.execute('mkdir -p '..outdir)
-- define utility tensors
local input = torch.FloatTensor(params.pfsz, maxsz)
local output = torch.FloatTensor(nphrases, params.pfsz)
local weightedsum = torch.FloatTensor(1,maxsz)
-- loop over phrases
for k,v in ipairs(phrases) do
  local length = v:nElement()
  if length == 0 then -- empty phrases, generate a random embeddings
    output[k]:apply(function() return torch.normal(mean,std) end)
  else
    weightedsum:resize(1,length):fill(1/length)
    input:resize(params.pfsz, length):index(lookup, 1, v)
    output:narrow(1,k,1):mm(weightedsum, input) -- averaging word embeddings
  end
end
-- create output file
local outfile = outdir..params.phr..'_'..params.pfsz..'d_ge'..params.t..'.bin'
print('writing phrase embeddings in ' .. outfile .. '...')
local fout = torch.DiskFile(outfile,'w'):binary()
fout:writeObject(output)
fout:close()
