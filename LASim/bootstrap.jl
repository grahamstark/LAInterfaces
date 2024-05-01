(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir
# Graham was here
using LASim
const UserApp = LASim
LASim.main()
