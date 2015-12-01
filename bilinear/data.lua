require 'torch'
local walker = dofile('walker.lua')

--------------------------------------------------------------------------------
-- Dataset
--------------------------------------------------------------------------------
local data={}
setmetatable(data,{
__call = function(self, params)

  ------------------------------------------------------------------------------
  -- Load Data
  ------------------------------------------------------------------------------
  -- load text features
  local function load(phr, t)
    local trainset={}
    for line in io.lines(params.data..'/text/image_'..phr..'_ge'..t..'.index') do
      local id,idx = line:match("(%d+)\t(%d+)")
      table.insert(trainset,{id=id,label=tonumber(idx)})
    end
    local trainsz = #trainset
    return trainset,trainsz
  end

  -- load training for each phrase
  local NP,NPsz = load('NP', params.minfreq)
  local VP,VPsz = load('VP', params.minfreq)
  local PP,PPsz = load('PP', params.minfreq)
  local trainset = {NP,VP,PP}
  local trainsz = {NPsz,VPsz,PPsz}
  local weighting = torch.Tensor(trainsz)
  local sampler = walker(weighting:div(weighting:sum()))

  -- load image features
  local f=torch.DiskFile(params.data .. '/image/features.bin','r'):binary()
  local trainfeatures=f:readObject()
  f:close()
  -- save image feature size for creating network later on
  params.ifsz = trainfeatures:size(2)
  -- load indexing for images
  local trainhash={}
  local nimages=0
  for line in io.lines(params.data .. '/image/id.txt') do
    nimages=nimages+1
    table.insert(trainhash, line)
    trainhash[line]=nimages
  end

  local set = {}

  -- function which return a random training sample
  function set:sample()
    local s = sampler()
    local idx = torch.random(trainsz[s])
    local t = trainset[s][idx]
    local x=trainfeatures:select(1, trainhash[t.id])
    local y=t.label
    return x,y,s
  end

  function set:nb_images()
      return nimages
  end

  function set:random_images()
        return trainhash[torch.random(nimages)]
  end
  function set:image_features(id)
      return trainfeatures:select(1, trainhash[id])
  end

  return set

end})

return data
