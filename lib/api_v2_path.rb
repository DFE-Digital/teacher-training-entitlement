# Recognises request paths served by API V2. Accepts a plain path or a full path
# with a query string, so it works for Rack paths and the exceptions app's
# original full path alike.
module APIV2Path
  PATTERN = %r{\A/+api/v2(/|\?|\z)}

  def self.match?(path)
    PATTERN.match?(path.to_s)
  end
end
