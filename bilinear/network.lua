require 'nn'
--------------------------------------------------------------------------------
-- Neural Network
--------------------------------------------------------------------------------
local network={}
setmetatable(network,{
__call = function(self, params)

  -- define global variable
  local pfsz = params.pfsz
  local neg = params.neg+1
  local lr = params.lr
  -- create training tensors
  local negsample = torch.Tensor(neg, pfsz)
  local y = torch.Tensor(neg)
  local sgoutput = torch.Tensor(neg)
  -- create gradInput tensor
  local sgGradInput = torch.Tensor(pfsz)
  local critGradInput = torch.Tensor(neg)

  -- load phrase lookup table
  -- for NP
  local fnp=torch.DiskFile(
    params.data..'/lookup/NP_'..params.pfsz..'d_ge'..params.t..'.bin'):binary()
  local NPlookuptable=fnp:readObject()
  fnp:close()
  -- for VP
  local fvp=torch.DiskFile(
    params.data..'/lookup/VP_'..params.pfsz..'d_ge'..params.t..'.bin'):binary()
  local VPlookuptable=fvp:readObject()
  fvp:close()
  -- for PP
  local fpp=torch.DiskFile(
    params.data..'/lookup/PP_'..params.pfsz..'d_ge'..params.t..'.bin'):binary()
  local PPlookuptable=fpp:readObject()
  fpp:close()
  local lookuptable = {NPlookuptable, VPlookuptable, PPlookuptable}
  local stdv = 1./math.sqrt(params.ifsz)
  local weights = torch.Tensor(params.pfsz,params.ifsz):uniform(-stdv,stdv)
  local input = torch.Tensor(params.pfsz)

  -- negative sampling function
  local function negative_sample(x, lookuptable)
    local phrasesz = lookuptable:size(1)
    -- get negative samples
    local itr=2
    while itr<=neg do
      local idx = torch.random(phrasesz)
      if idx ~= x then
        y[itr]=idx
        negsample:select(1,itr):copy(lookuptable:select(1,idx))
        itr=itr+1
      end
    end
  end

  local net = {}
  -- training function
  function net:train(x, label, phr)
    local err=0
    -- set ground truth
    -- get phrase representation
    local gt = lookuptable[phr]:select(1,label)
    negsample:select(1,1):copy(gt)
    y[1] = label

    -- get negative sample
    negative_sample(label, lookuptable[phr])
    -- project image into phrase vector space
    input:addmv(0, 1, weights, x)
    -- dot product between images and phrases
    sgoutput:addmv(0, 1, negsample, input)

    -- loop over negative sample
    for j=1,neg do
      -- get score
      local f = sgoutput[j]
      -- get label
      local label = -1
      if j == 1 then label = 1 end
      -- compute the gradient
      err = err +  math.log(1+math.exp(-label*f))
      critGradInput[j] = -label/(1+math.exp(label*f))
    end
    err = err / neg
    -- accumulate gradient
    sgGradInput:addmv(0, 1, negsample:t(), critGradInput)
    -- update parameters for predictor layer
    for j=1,neg do
        lookuptable[phr]:select(1,y[j]):add(-lr*critGradInput[j], input)
    end
    -- update parameters
    weights:addr( -lr, sgGradInput, x)
    -- return error
    return err
  end

  -- save parameters
  function net:save(dir)
    io.write('# saving model...')
    io.flush()
      -- save network
    local fmodel = torch.DiskFile(dir..'/weights.bin', 'w'):binary()
    fmodel:writeObject(weights)
    fmodel:close()
    local fnp = torch.DiskFile(dir..'/NPlookup.bin', 'w'):binary()
    fnp:writeObject(NPlookuptable)
    fnp:close()
    local fvp = torch.DiskFile(dir..'/VPlookup.bin', 'w'):binary()
    fvp:writeObject(VPlookuptable)
    fvp:close()
    local fpp = torch.DiskFile(dir..'/PPlookup.bin', 'w'):binary()
    fpp:writeObject(PPlookuptable)
    fpp:close()
    io.write("\n")
  end

  return net
end})

return network



