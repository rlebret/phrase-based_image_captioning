require 'torch'

local walker = {}

setmetatable(walker, {
  __call = function(self, X)
              assert(X:dim() == 1)
              local N = X:size(1)

              local Y = torch.DoubleTensor(N+2)
              Y[1] = 0
              Y[N+2] = 0
              Y:narrow(1, 2, N):copy(X)
              Y:div(X:sum())

              local A = torch.LongTensor(N+2)
              local B = torch.LongTensor(N+2)
              walker.build(Y:data(),
                           N,
                           A:data(),
                           B:data())

              local sampler = {}
              setmetatable(sampler, {
                              __call = function()
                                          return walker.sample(Y:data(),
                                                               N,
                                                               A:data())
                                       end
                           })

              return sampler
           end
})

function walker.sample(Y, N, A)
   -- Let i = random uniform integer from {1,2,...N};
   local i = torch.random(1, N)
   local r = torch.uniform()
   if r > Y[i] then
      i = tonumber(A[i])
   end
  return i
end

function walker.build(X, N, A, B)
   assert (1 <= N);
   for i=1,N do
      A[i] = i
      B[i] = i -- initial destins=stay there
      assert(X[i] >= 0.0)
      X[i] = X[i] * N; -- scale probvec
   end
   B[0] = 0
   X[0] = 0.0
   B[N + 1] = N + 1
   X[N + 1] = 2.0 -- sentinels

   local i = 0
   local j = N + 1
   while true do

      -- find i so X[B[i]] needs more
      repeat
         i = i + 1
      until X[B[i]] >= 1.0

      -- find j so X[B[j]] wants less
      repeat
         j = j - 1
      until X[B[j]] < 1.0

      if i >= j then
         break
      end

      -- swap B[i], B[j]
      local k = B[i]
      B[i] = B[j]
      B[j] = k
   end

   i = j
   j = j + 1
   while i > 0 do
      -- find j so X[B[j]] needs more
      while X[B[j]] <= 1.0 do
         j = j + 1
      end

      -- meanwhile X[B[i]] wants less
      assert(X[B[i]] < 1.0)
      if j > N then
         break
      end

      assert (j <= N)
      assert (X[B[j]] > 1.0)

      -- B[i] will donate to B[j] to fix up
      X[B[j]] = X[B[j]] - (1.0 - X[B[i]])
      A[B[i]] = B[j]

      if X[B[j]] < 1.0 then
         -- X[B[j]] now wants less so readjust ordering
         assert (i < j)
         -- swap B[j], B[i]
         local k = B[i]
         B[i] = B[j]
         B[j] = k
         j = j + 1
      else
         i = i - 1
      end
   end
end

return walker
