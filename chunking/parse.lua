-- each line contains image id in first column, then image captions in the
-- next columns.
-- each column is separated with tabulations.
-- example for an image with 3 captions:
-- image_id  caption1  caption2  caption3

local infile = arg[1] -- input file
local outdir = arg[2] -- directory where to save the files
local fid = io.open(outdir..'/id.txt','w')
local fsent = io.open(outdir..'/sentences.txt','w')
local fnb = io.open(outdir..'/nb.txt','w')
for line in io.lines(infile) do
  local imageid, captions = line:match('(%d+)(\t.*)')
  local t={}
  for sent in captions:gmatch('\t(.-)') do
    table.insert(t,sent)
  end
  if #t>0 then -- sanity check
    fid:write(imageid..'\n')
    fnb:write(#t..'\n')
    fsent:write(table.concat(t, '\n'))
  end
end
fid:close()
fsent:close()
fnb:close()
