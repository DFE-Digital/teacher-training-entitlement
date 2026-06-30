uri = URI(ENV.fetch("HOSTING_DOMAIN"))

Rails.application.routes.default_url_options = {
  host: uri.host,
  port: uri.port,
  protocol: uri.scheme,
}
