-- each line contains image id in first column, then image captions in the
-- next columns.
-- each column is separated with tabulations.
-- example for an image with 3 captions:
-- image_id  caption1  caption2  caption3

-- Compatibility: Lua-5.0
local function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

local infile = arg[1] -- input file
local outdir = arg[2] -- directory where to save the files
local fid = io.open(outdir..'/id.txt','w')
local fsent = io.open(outdir..'/sentences.txt','w')
local fnb = io.open(outdir..'/nb.txt','w')
for line in io.lines(infile) do
  local imageid, captions = line:match('(%d+)\t(.*)')
  local t=Split(captions, '\t')
  if #t>0 then -- sanity check
    fid:write(imageid..'\n')
    fnb:write(#t..'\n')
    fsent:write(table.concat(t, '\n')..'\n')
  end
end
fid:close()
fsent:close()
fnb:close()
