require 'torch'

cmd = torch.CmdLine()
cmd:text()
cmd:text('Computing phrase embeddings nearest neighbors')
cmd:text()
cmd:text()
cmd:text('Misc options:')
cmd:option('-phr', '', 'phrase type {NP,VP,PP}')
cmd:option('-pfsz', 400, 'phrase embeddings size')
cmd:option('-t', 10, 'phrase appearance frequency')
cmd:option('-dir', '', 'where to find and save data')
cmd:text()
cmd:text()
local params = cmd:parse(arg)

local outdir = params.dir .. '/lookup/'
local outfile = outdir..params.phr..'_'..params.pfsz..'d_ge'..params.t..'.bin'
print('loading phrase embeddings in ' .. outfile .. '...')
local fout = torch.DiskFile(outfile,'r'):binary()
local emb = fout:readObject()
fout:close()
--------------------------------------------------------------------------------
-- Loading phrases
--------------------------------------------------------------------------------
-- get phrase from vocabulary
local phrases={}
local phrasesz=0
for line in io.lines(params.dir..'/vocab/'..params.phr..'.txt') do
  local ph,fq=line:match('(.-)\t(%d+)')
  fq=tonumber(fq)
  if fq<params.t then break end
  phrasesz=phrasesz+1
  table.insert(phrases,ph)
  phrases[ph] = phrasesz
end
print('# of '..params.phr..' = '.. phrasesz)

local  distances = torch.Tensor(phrasesz)
local  sortedindices = torch.LongTensor(phrasesz)
local  sortedvalues = torch.Tensor(phrasesz)

local out = io.open(outdir..params.phr..'_'..params.pfsz..'d_ge'..params.t..'.neighbors','w')
for i=1,phrasesz do
    local res=phrases[i]..' --> '
    local input = emb[i]
    -- get neighbors
    distances:fill(math.huge)
    for j=1,phrasesz do
        if j ~= i then
            local inputj = emb[j]
            distances[j] = input:dist(inputj)
        end
    end
    torch.sort( sortedvalues, sortedindices, distances, 1, false )
    -- write results
    local t={}
    for neigh=1,10 do
        table.insert(t,phrases[sortedindices[neigh]])
    end
    out:write(res..table.concat(t,', ')..'\n')
    out:flush()
end
out:close()
