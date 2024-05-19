using Genie.Router

route("/run", LASim.submit_job, method=POST )

route("/reset", LASim.reset, method=POST )

route("/load", LASim.load_all, method=POST )

route("/switch_system", LASim.switch_system, method=POST )

route("/addincome-contribution/:n", method = POST) do 
  n::Int = parse(Int, payload(:n))
  LASim.addincome( n )
end

route("/delincome-contribution/:n", method = POST ) do
  n::Int = parse(Int, payload(:n))
  LASim.delincome( n )
end

route("/addcapital-contribution/:n", method = POST ) do 
  n::Int = parse(Int, payload(:n))
  LASim.addcapital( n )
end

route("/delcapital-contribution/:n", method = POST ) do 
  n::Int = parse(Int,  payload(:n))
  LASim.delcapital( n )
end

route("/") do
  serve_static_file("indexloc.html")
end

route( "/progress", LASim.getprogress, method = POST )

route( "/output", method = POST ) do 
  LASim.get_output()
end