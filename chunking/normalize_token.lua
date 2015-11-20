local dir = arg[1]
local infile = dir .. '/sentences.token'
local outfile = dir .. '/sentences.final'

-- replace substring recursively
function replace(str,a,b)
  local n
  str,n=str:gsub(a, b)
  while n > 0 do
    str,n=str:gsub(a, b)
  end
  return str
end

local file = io.open(outfile,'w')
-- get tokens from file
for line in io.lines(infile) do
    -- lowercase
    line=line:lower()
    -- get back bracket (needed for SENNA)
    line=line:gsub("%-lrb%-","%(")
    line=line:gsub("%-rrb%-","%)")
    -- replace digits
    line=line:gsub("%d+", "0")
    line=replace(line, "0,0", "0")
    line=replace(line, "0[.]0", "0")
    -- check whether last token is a period
    if line:sub(line:len()-1,line:len()) ~= ' .' then
      line = line .. ' .'
    end
    file:write(line..'\n')
end
-- close file
file:close()

