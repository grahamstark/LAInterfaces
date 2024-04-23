using Genie, Logging, Revise

Genie.Configuration.config!(
  server_port                     = 8025,
  server_host                     = "127.0.0.1",
  log_level                       = Logging.Info,
  log_to_file                     = false,
  path_log                        = "/tmp/",
  server_handle_static_files      = true,
  server_document_root            = "web/",
  path_build                      = "build",
  format_julia_builds             = true,
  format_html_output              = true,
  watch                           = true
)

ENV["JULIA_REVISE"] = "auto"

