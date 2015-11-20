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
    local set={}
    for line in io.lines(params.data..'/text/image_'..phr..'_ge'..t..'.index') do
      local id,idx = line:match("(%d+)\t(%d+)")
      table.insert(trainset,{id=tonumber(id),label=tonumber(idx)})
    end
    local trainsz = #trainset
    return trainset,trainsz
  end

  -- load training for each phrase
  local NP,NPsz = load('NP', params.t)
  local VP,VPsz = load('VP', params.t)
  local PP,PPsz = load('PP', params.t)
  local trainset = {NP,VP,PP}
  local trainsz = {NPsz,VPsz,PPsz}
  local weighting = torch.Tensor(trainsz)
  local sampler = walker(weighting:div(weighting:sum()))
  local rd = {torch.randperm(NPtrainsz), torch.randperm(VPtrainsz),torch.randperm(PPtrainsz)}

  -- load image features
  local f=torch.DiskFile(params.data .. '/image/features.bin','r'):binary()
  local trainfeatures=f:readObject()
  f:close()
  -- save image feature size for creating network later on
  params.ifsz = trainfeatures:size(2)
  -- load indexing for images
  local trainhash={}
  local trainsz=0
  for line in io.lines(params.data .. '/image/id.txt') do
    trainsz=trainsz+1
    trainhash[tonumber(line)]=trainsz
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

  return set

end})

return data
