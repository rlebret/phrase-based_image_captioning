local dir = arg[1]
local filename = dir .. '/sentences.chk'
local chkfile = io.open(filename,'r')
local outfile = io.open(filename .. 'sz','w')

-- loop over lines
local chksz = {}
local line = chkfile:read('*line')
while line ~= nil do
  if (line:find('%(.+%)')~=nil)  then
    local pattern=line:match('%((.+)%*%)')
    table.insert(chksz,'1-'..pattern)
  elseif line:find('%(.+') ~= nil then
    local itr=2
    local pattern=line:match('%((.+)%*')
    while line ~= '' do
      line = chkfile:read('*line')
      if (line:find('.+%)')~=nil) then
        break
      end
      if line == '' then break end
      itr=itr+1
    end
    table.insert(chksz,itr..'-'..pattern)
  elseif (line:find('%*')~=nil) then
    table.insert(chksz,'1-O')
  end
  --print(k)
  if line == '' then
    outfile:write(table.concat(chksz, ' ')..'\n')
    chksz = {}
  end
  line = chkfile:read('*line')
end
-- close file
outfile:close()
chkfile:close()
