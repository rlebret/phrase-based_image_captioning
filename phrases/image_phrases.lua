local phrase = arg[1]
local dir = arg[2]
local t=tonumber(arg[3])
local outdir = dir .. '/text/'
os.execute('mkdir -p '..outdir)
local vocabfile=dir .. '/vocab/' .. phrase .. '.txt'
local phrases={}
local n=0
for line in io.lines(vocabfile) do
  local phr,fq=line:match("(.-)\t(%d+)")
  fq = tonumber(fq)
  if fq>=t then
    n=n+1
    phrases[phr]=n
  else
    break
  end
end
print('# of '..phrase .. ' = '..n)


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
local tab={}
for i=1,#setsz do
  local id = setids[i]
  table.insert(tab,{})
  tab[#tab].idwtf=id
  tab[id] = #tab
  local t=tab[tab[id]]

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
    local itr=1
    for k,v in ipairs(chunk) do
      if v.ph==phrase then
        local j = math.min(#sent,itr+v.sz-1)
        local str = table.concat(sent, " ", itr, j)
        if t[str]==nil then
          table.insert(t,str)
          t[str]=1
        else
          t[str]=t[str]+1
        end
      end
      itr=itr+v.sz
    end
  end
end
fsent:close()
fchk:close()
print('# of images = ' ..#tab)

local fout=io.open(outdir..'/image_'..phrase..'_ge'..t..'.txt','w')
local fout2=io.open(outdir..'/image_'..phrase..'_ge'..t..'.index','w')
for _,t in ipairs(tab) do
  table.sort(t,function(a,b) return t[a]>t[b] end)
  for _,v in ipairs(t) do
    if phrases[v] then
      fout:write(t.idwtf..'\t'..t[v]..'\t'..v..'\n')
      for i=1,t[v] do
        fout2:write(t.idwtf..'\t'..phrases[v]..'\n')
      end
    end
  end
end
fout:close()
fout2:close()
