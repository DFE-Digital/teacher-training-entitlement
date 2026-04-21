module Middleware
  module ApiHelper
    def api_path?(env)
      Rack::Request.new(env).path.match?(%r{^/+api/v\d+(/.*)?$})
    end
  end
end
