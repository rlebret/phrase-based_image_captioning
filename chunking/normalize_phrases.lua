local dir=arg[1]
local infile = dir..'/sentences.chksz'
local outfile = infile .. 'final'
local fout=io.open(outfile,'w')
for line in io.lines(infile) do
  local t={}
  for sz,ph in line:gmatch('(%d+)%-(%S+)') do
    table.insert(t,{sz=sz,ph=ph})
  end
  local itr=1
  local out={}
  while itr<#t do
    if t[itr].ph=='VP' then
      local newsz=t[itr].sz
      local i=1
      while t[itr+i].ph ~= 'NP' and t[itr+i].ph ~= 'O' do
        newsz=newsz+t[itr+i].sz
        i=i+1
      end
      table.insert(out,newsz..'-VP')
      itr=itr+i
    elseif t[itr].ph=='ADVP' then
      local newsz=t[itr].sz
      if t[itr+1].ph == 'PP' then
        newsz=newsz+t[itr+1].sz
        itr=itr+1
      end
      table.insert(out,newsz..'-PP')
      itr=itr+1
    else
      table.insert(out,t[itr].sz..'-'..t[itr].ph)
      itr=itr+1
    end
  end
  table.insert(out,'1-O') -- add period
  fout:write(table.concat(out, ' ')..'\n')
end
fout:close()
