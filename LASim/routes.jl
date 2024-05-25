using Genie.Router
using UUIDs
using LASim

route("/run", method=POST ) do 
  LASim.submit_job()
end

route("/reset", method=POST ) do
  uuid, systype = LASim.sys_and_uuid_from_payload() 
  LASim.reset( uuid, systype )
end

route("/load", method=POST ) do 
  LASim.load_all()
end

# just differs in 
route("/initial_load", method=POST ) do 
  LASim.load_all()
end

route("/switch_system", method=POST ) do
  uuid, systype = LASim.sys_and_uuid_from_payload() 
  LASim.switch_system( uuid, systype )
end

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
  uuid, systype = LASim.sys_and_uuid_from_payload()
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
  ss = payload( :systype )
  @assert ss in ["sys_civil", "sys_aa"]
  systype = ss == "sys_civil" ? sys_civil : sys_aa
  uuid = UUID( payload(:uuid))
  # uuid, systype = LASim.sys_and_uuid_from_payload()
  LASim.getprogress( uuid, systype )
end

route( "/output", method = POST ) do 
  LASim.get_output()
end