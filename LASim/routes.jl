using Genie.Router
using UUIDs

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

route( "/clearout/:uuid", method = POST ) do
  uuid = UUID(payload(:uuid))
  LASim.clearout(uuid)
end

route("/delcapital-contribution/:n", method = POST ) do 
  n::Int = parse(Int,  payload(:n))
  LASim.delcapital( n )
end

route("/") do
  serve_static_file("index.html")
end

route( "/progress", method = POST ) do
  @show "route: progress entered"
  uuid = UUID( payload(:uuid))
  ss = payload(:systype)
  @assert( ss in ["sys_civil", "sys_aa"])
  systype = ss == "sys_civil" ? sys_civil : sys_aa
  @show "route: uuid=$uuid"
  LASim.getprogress( uuid, systype )
end

route( "/output", method = POST ) do 
  LASim.get_output()
end