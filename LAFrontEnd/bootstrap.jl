(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using LAFrontEnd
const UserApp = LAFrontEnd
LAFrontEnd.main()
