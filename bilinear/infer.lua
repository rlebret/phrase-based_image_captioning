require 'nn'
local data = dofile('data.lua')
torch.setdefaulttensortype('torch.FloatTensor')

cmd = torch.CmdLine()
cmd:text()
cmd:text('Inference of chunk phrases describing images')
cmd:text()
cmd:text()
cmd:text('Misc options:')
cmd:option('-model', '', 'directory where the model are')
cmd:option('-img', 'images', 'path to directory containing images')
cmd:option('-seed', 1111, 'seed')
cmd:option('-topnp', 20, 'number of best NP to display')
cmd:option('-topvp', 5, 'number of best VP to display')
cmd:option('-toppp', 5, 'number of best PP to display')
cmd:option('-display', false, 'display image')
cmd:text()
cmd:text()

local inferparams = cmd:parse(arg)
-- fix a seed
torch.manualSeed(inferparams.seed)
-- setup display
local window
if inferparams.display then
    require 'image'
    require 'qtwidget'
    window = qtwidget.newwindow(500,500)
end
-- load parameters
local fparams = torch.DiskFile(inferparams.model..'/params.bin','r'):binary()
local params = fparams:readObject()
fparams:close()
--------------------------------------------------------------------------------
-- Load datasets
--------------------------------------------------------------------------------
local train = data(params)
--------------------------------------------------------------------------------
-- Load model
--------------------------------------------------------------------------------
io.write('# loading model...')
io.flush()
  -- save network
local fmodel = torch.DiskFile(params.out..'/weights.bin', 'r'):binary()
local weights = fmodel:readObject()
fmodel:close()
local fnp = torch.DiskFile(params.out..'/NPlookup.bin', 'r'):binary()
local NPlookuptable = fnp:readObject()
fnp:close()
local fvp = torch.DiskFile(params.out..'/VPlookup.bin', 'r'):binary()
local VPlookuptable = fvp:readObject()
fvp:close()
local fpp = torch.DiskFile(params.out..'/PPlookup.bin', 'r'):binary()
local PPlookuptable = fpp:readObject()
fpp:close()
io.write("\n")
--------------------------------------------------------------------------------
-- get phrase from vocabulary
--------------------------------------------------------------------------------
local function load_vocab(phr)
    local vocab={}
    local vocabsz=0
    for line in io.lines(params.data..'/vocab/'..phr..'.txt') do
      local ph,fq=line:match('(.-)\t(%d+)')
      fq=tonumber(fq)
      if fq<params.minfreq then break end
      vocabsz=vocabsz+1
      table.insert(vocab,ph)
      vocab[ph] = vocabsz
    end
    print('# of '..phr..' = '.. vocabsz)
    return vocab, vocabsz
end
local NP = load_vocab('NP')
local VP = load_vocab('VP')
local PP = load_vocab('PP')

local input = torch.FloatTensor(params.pfsz)
local outputsz = NPlookuptable:size(1)
local output = torch.FloatTensor(outputsz)
local sortedvalues = torch.FloatTensor(outputsz)
local sortedindices = torch.LongTensor(outputsz)

local function get_top_phrases(lookuptable, vocab, n)
    local sz = lookuptable:size(1)
    output:resize(sz):addmv(0, 1, lookuptable, input)
    sortedindices:resize(sz)
    sortedvalues:resize(sz)
    torch.sort(sortedvalues, sortedindices, output, 1, true)
    local t={}
    for i=1,n do
        table.insert(t, i .. '\t'..vocab[sortedindices[i]] .. '\t' .. output[sortedindices[i]])
    end
    return table.concat(t, '\n')
end

local function infer(x)
    input:addmv(0, 1, weights, x)
    print('-- top NP:')
    print(get_top_phrases(NPlookuptable, NP, inferparams.topnp))
    print('-- top VP:')
    print(get_top_phrases(VPlookuptable, VP, inferparams.topvp))
    print('-- top PP:')
    print(get_top_phrases(PPlookuptable, PP, inferparams.toppp))
end

local nimages = train:nb_images()
print('# of images = '..nimages)

for file in paths.files(inferparams.img,'.jpg') do
    file = inferparams.img .. '/' .. file
    if inferparams.display then
        image.display({image=image.load(file),win=window})
    end
    local id = paths.basename(file,'.jpg')
    print('----> image #'..id)
    local feat = train:image_features(id)
    infer(feat)
    io.read()
end
