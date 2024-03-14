using Genie.Router

route("/run", LASim.run, method=POST )

route("/reset", LASim.reset, method=POST )

route("/addincome/:n", method = POST) do 
  n::Int = parse(Int, payload(:n))
  LASim.addincome( n )
end

route("/delincome/:n", method = POST ) do
  n::Int = parse(Int, payload(:n))
  LASim.delincome( n )
end

route("/addcapital/:n", method = POST ) do 
  n::Int = parse(Int, payload(:n))
  LASim.addcapital( n )
end

route("/delcapital/:n", method = POST ) do 
  n::Int = parse(Int,  payload(:n))
  LASim.delcapital( n )
end

route("/") do
  serve_static_file("indexloc.html")
end