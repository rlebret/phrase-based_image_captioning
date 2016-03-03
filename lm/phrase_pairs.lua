local vocab = paths.dofile('vocab.lua')
local dir = arg[1]
local t=tonumber(arg[2])
local outdir = dir .. '/text/'

-- local vocabularies
local NP = vocab(dir .. '/vocab/NP.txt', t, true) -- load NP
local VP = vocab(dir .. '/vocab/VP.txt', t, true) -- load VP
local PP = vocab(dir .. '/vocab/PP.txt', t, true) -- load PP
-- define output files
local fout1=io.open(outdir..'/image_START-NP_ge'..t..'.txt','w')
local fout2=io.open(outdir..'/image_NP-PP_ge'..t..'.txt','w')
local fout3=io.open(outdir..'/image_NP-VP_ge'..t..'.txt','w')
local fout4=io.open(outdir..'/image_PP-NP_ge'..t..'.txt','w')
local fout5=io.open(outdir..'/image_VP-NP_ge'..t..'.txt','w')
local fout6=io.open(outdir..'/image_NP-PERIOD_ge'..t..'.txt','w')

-- load training sentences
local setsz={}
for line in io.lines(dir..'/nb.txt') do
  table.insert(setsz,tonumber(line))
end
print('# of images = '..#setsz)
local setids={}
for line in io.lines(dir..'/id.txt') do
  table.insert(setids,line)
end
print('# of ids = '..#setids)
local fsent = io.open(dir..'/sentences.final','r')
local fchk = io.open(dir..'/sentences.chkszfinal','r')
-- loop over training images
for i=1,#setsz do
  local id = setids[i]
  for k=1,setsz[i] do
    local sentline=fsent:read()
    local chkline=fchk:read()
    local chunk={}
    -- add it to avoid error in line 90 in this file
    chunk[0] = 'skip'
    
    for sz,ph in chkline:gmatch('(%d+)%-(%S+)') do
      table.insert(chunk,{ph=ph,sz=sz})
    end
    local sent={}
    for word in sentline:gmatch('%S+') do
      table.insert(sent,word)
    end

    -- P(NP | START)
    if chunk[1].ph=='NP' then
      local np = table.concat(sent, ' ', 1, chunk[1].sz)
      if NP:get(np)>0 then
          fout1:write(id..'\t'..np..'\n')
      end
    end
    local itr=1
    for i=1,#chunk-2 do -- last chunk is always PERIOD (i.e. 1-O)
      local c1 = chunk[i]
      local c2 = chunk[i+1]
      -- concat words
      local chk1 = table.concat(sent, ' ', itr, itr+c1.sz-1)
      local chk2 = table.concat(sent, ' ', itr+c1.sz, itr+c1.sz+c2.sz-1)
      local fout
      if c1.ph=='NP' and c2.ph=='PP' then -- P(PP | NP)
        if NP:get(chk1)>0 and PP:get(chk2)>0 then -- chunks in vocab?
          fout = fout2
        end
      elseif c1.ph=='NP' and c2.ph=='VP' then -- P(VP | NP)
        if NP:get(chk1)>0 and VP:get(chk2)>0 then -- chunks in vocab?
            fout = fout3
        end
      elseif c1.ph=='PP' and c2.ph=='NP' then -- P(NP | VP)
        if PP:get(chk1)>0 and NP:get(chk2)>0 then -- chunks in vocab?
          fout = fout4
        end
      elseif c1.ph=='VP' and c2.ph=='NP' then -- P(NP | PP)
        if VP:get(chk1)>0 and NP:get(chk2)>0 then -- chunks in vocab?
          fout = fout5
        end
      end
      -- did it find a transition?
      if fout ~= nil then
        -- write in the right file
        fout:write(id .. '\t' .. chk1 ..'\t' .. chk2 .. '\n' )
      end
      itr=itr+c1.sz
    end

    -- P(PERIOD | NP)
    if chunk[#chunk-1].ph=='NP' then
      local np = table.concat(sent, ' ', itr, itr+chunk[#chunk-1].sz-1)
      if NP:get(np)>0 then
        fout6:write(id..'\t'..np..'\n')
      end
    end
  end
end
-- closing files
fsent:close()
fchk:close()
fout1:close()
fout2:close()
fout3:close()
fout4:close()
fout5:close()
fout6:close()
