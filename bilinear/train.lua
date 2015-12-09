require 'torch'
local network = dofile('network.lua')
local data = dofile('data.lua')
torch.setdefaulttensortype('torch.FloatTensor')

cmd = torch.CmdLine()
cmd:text()
cmd:text('Bilinear model for chunk phrases describing images')
cmd:text()
cmd:text()
cmd:text('Misc options:')
cmd:option('-data', '', 'directory where the data are')
cmd:option('-out', '.', 'directory where to save stuff')
cmd:option('-minfreq', 10, 'minimum appearance frequency for phrases')
cmd:option('-pfsz', 400, 'phrase vector feature size')
cmd:option('-neg', 15, 'number of negative samples')
cmd:option('-seed', 1111, 'seed')
cmd:option('-nbiter', 100, 'number of iterations')
cmd:option('-lr', 0.0025, 'learning rate')
cmd:option('-epoch', 100000, 'number of epoch')
cmd:text()
cmd:text()

local params = cmd:parse(arg)
-- fix a seed
torch.manualSeed(params.seed)
--------------------------------------------------------------------------------
-- create directory to save the stuff
--------------------------------------------------------------------------------
local rundir = cmd:string('exp', params, {data=true})
if params.out ~= '.' then
    rundir = params.out .. '/' .. rundir
end
params.out = rundir
os.execute('mkdir -p ' .. rundir)
-- create log file
cmd:log(rundir .. '/log', params)

-- save parameters
local fparams = torch.DiskFile(rundir..'/params.bin', 'w'):binary()
io.write('# saving parameters...')
io.flush()
fparams:writeObject(params)
fparams:close()
print('ok')
--------------------------------------------------------------------------------
-- Load datasets
--------------------------------------------------------------------------------
local train = data(params)
--------------------------------------------------------------------------------
-- Neural Network
--------------------------------------------------------------------------------
local net = network(params)
--------------------------------------------------------------------------------
-- Training
--------------------------------------------------------------------------------
-- open files to save stuff
local fcost = io.open(rundir..'/cost', 'w')
local timer = torch.Timer()
-- loop over iterations
for itr=1,params.nbiter do
    print("Iteration #"..itr)
    timer:reset()
    local cost=0
    for k=1,params.epoch do
        local x, y, phr = train:sample()
        local err = net:train(x, y, phr)
        cost = cost + err
    end
    -- save cost
    cost = cost/params.epoch
    print(string.format('# cost = %.5f', cost))
    print(string.format('# ex/s = %.2f', params.epoch/timer:time().real))
    fcost:write(cost..'\n')
    fcost:flush()
    ----------------------------------------------------------------------------
    -- save model
    ----------------------------------------------------------------------------
    net:save(rundir)
    collectgarbage()
end
fcost:close()
print('Time elapsed for '..params.nbiter..' iterations: ' .. timer:time().real .. ' seconds')
