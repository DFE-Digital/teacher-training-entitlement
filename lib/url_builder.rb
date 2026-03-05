module UrlBuilder
  def self.build_url(path)
    hosting_domain = ENV["HOSTING_DOMAIN"].presence
    hosting_domain ? URI.join(hosting_domain, path) : path
  end
end
