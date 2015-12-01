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
  vocab[vocabsz]=vocabsz
end
print("# of word embeddings = "..vocabsz)
---- load embeddings which are in a torch.FloatTensor(nword, dim)
local femb = torch.DiskFile(params.emb, 'r'):binary()
-- get size
femb:seekEnd()
local wfsz = (f:position()-1)/4/vocabsz
if wfsz < params.pfsz then
  error('word embeddings dimension (=' .. wfsz .. ') is too small')
end
femb:seek(1)
print('loading word embeddings...')
local emb = torch.FloatTensor(vocabsz,wfsz)
femb:readFloat(emb:storage())
femb:close()
local lookup = tmp:narrow(2, 1, pfsz) -- get the required dimension
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
local weightedsum = torch.FLoatTensor(1,maxsz)
print('writing phrase embeddings in ' .. outfile .. '...')
-- loop over phrases
for k,v in ipairs(phrases) do
  local length = v:nElement()
  if length == 0 then -- empty phrases, generate a random embeddings
    output[k]:apply(function() return torch.normal(mean,std) end)
  else
    weightedsum:resize(1,length):fill(1/length)
    input:resize(params.pfsz, length):index(lookup, 1, v)
    output[k]:mm(weightedsum, input) -- averaging word embeddings
  end
end
-- create output file
local outfile = outdir..phrase..'_'..pfsz..'d_ge'..params.t..'.bin'
local fout = torch.DiskFile(outfile,'w'):binary()
fout:writeObject(output)
fout:close()

