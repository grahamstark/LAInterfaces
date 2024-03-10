using Genie.Router

route("/run", LASim.run, method=GET )

route("/") do
  serve_static_file("welcome.html")
end