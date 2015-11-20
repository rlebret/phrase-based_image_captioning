require 'torch'
local tds = require 'tds'
--------------------------------------------------------------------------------
-- Vocabulary
--------------------------------------------------------------------------------
local vocab={}
setmetatable(vocab,{
__call = function(self, file, min_freq, verbose)
    verbose = verbose or true

    local function load(phr)
      -- body
    end
    local phrases=tds.hash()
    local freq=tds.hash()
    local vocabsz=0
    -- loop over vocabulary lines
    for line in io.lines(file) do
        local phr,fq = line:match('(.-)\t(%d+)')
        fq = tonumber(fq)
        if fq >= min_freq then
            vocabsz=vocabsz+1 -- increment vocabulary size
            -- store phrase
            phrases[vocabsz]=phr
            phrases[phr]=vocabsz
        end
        -- store phrase frequency
        freq[phr]=fq
    end
    -- set unknown
    local unkn = vocabsz+1

    if verbose then
        print(' --> # of phrases in '..file..' = ' .. vocabsz)
    end

    local data = {}

    function data:size()
        return vocabsz
    end

    function data:unkn()
        return unkn
    end

    function data:get(phr)
        return phrases[phr], freq[phr]
    end

    function data:phrases()
        return phrases
    end

    return data
end})

return vocab
