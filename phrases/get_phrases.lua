local group = arg[1] -- chunk type (NP, VP or PP)
local dir = arg[2]
local chkfile = io.open(dir..'/sentences.chkszfinal','r') -- file containing chunk size
local sentfile = io.open(dir..'/sentences.final','r') -- file containing tokenized sentence
os.execute('mkdir -p ' .. dir .. '/vocab')
local outfilename = dir .. '/vocab/' .. group .. '.txt' -- vocabulary file

-- loop over lines
local chkline = chkfile:read('*line')
local sentline = sentfile:read('*line')
local vocab={}
while chkline ~= nil do
  local chk={}
  for c in chkline:gmatch('%S+') do
    table.insert(chk,c)
  end
  local sent={}
  for c in sentline:gmatch('%S+') do
    table.insert(sent,c)
  end
  if sent[#sent] ~= '.' then table.insert(sent,'.') end

  local itr=1
  for i=1,#chk do
    local sz,pattern = chk[i]:match('(%d+)%-(.+)')
    sz=tonumber(sz)
    if pattern == group then
      --print(chkline,sentline)
      local j = math.min(#sent,itr+sz-1)
      local np=table.concat(sent,' ',itr,j)
      if vocab[np] == nil then
        table.insert(vocab,np)
        vocab[np]=1
      else
        vocab[np]=vocab[np]+1
      end
    end
    itr=itr+sz
  end
  chkline = chkfile:read('*line')
  sentline = sentfile:read('*line')
end
-- close files
chkfile:close()
sentfile:close()

table.sort(vocab, function(a,b) return vocab[a]>vocab[b] end)
local outfile = io.open(outfilename,'w')
for k,v in ipairs(vocab) do
  outfile:write(v .. '\t'.. vocab[v]..'\n')
end
outfile:close()
