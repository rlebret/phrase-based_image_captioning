--------------------------------------------------------------------------------
-- Vocabulary
--------------------------------------------------------------------------------
local vocab={}
setmetatable(vocab,{
__call = function(self, file, min_freq, verbose)
    verbose = verbose or true

    local phrases={}
    local vocabsz=0
    -- loop over vocabulary lines
    for line in io.lines(file) do
        local phr,fq = line:match('(.-)\t(%d+)')
        fq = tonumber(fq)
        if fq >= min_freq then
            vocabsz=vocabsz+1 -- increment vocabulary size
            -- store phrase
            table.insert(phrases,phr)
            phrases[phr]=vocabsz
        else
            break
        end
    end
    -- set unknown
    local unkn = vocabsz+1

    if verbose then
        print(' --> # of phrases in '..file..' = ' .. vocabsz)
    end

    local data = {

    }

    function data:size()
        return vocabsz
    end

    function data:unkn()
        return unkn
    end

    function data:get(phr)
        if phrases[phr] == nil then
            return -1
        else
            return phrases[phr]
        end
    end

    function data:phrases()
        return phrases
    end

    setmetatable(data,{
    __index = function(self, index)
        return phrases[index]
    end})

    return data
end})

return vocab
