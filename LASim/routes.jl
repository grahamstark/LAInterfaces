using Genie.Router

route("/run", LASim.run, method=POST )
route("/reset", LASim.reset, method=POST )
route("/") do
  serve_static_file("welcome.html")
end