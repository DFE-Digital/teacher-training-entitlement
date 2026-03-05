source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "activerecord-session_store"
gem "azure-blob"
gem "blueprinter"
gem "bootsnap", require: false
gem "countries"
gem "cssbundling-rails"
gem "daemons"
gem "delayed_cron_job"
gem "delayed_job"
gem "delayed_job_active_record"
gem "devise", "~> 5.0"
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.15.15"
gem "email_validator", require: "email_validator/strict"
gem "flipper"
gem "flipper-active_record"
gem "google-cloud-bigquery"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "govuk_markdown"
gem "httparty"
gem "jsbundling-rails"
gem "mail-notify"
gem "method_source"
gem "oj"
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "paper_trail"
gem "pg"
gem "pg_search"
gem "puma"
gem "rack-attack"
gem "rails", "~> 8.1.2"
gem "rails_semantic_logger"
gem "redis"
gem "rouge"
gem "secure_headers"
gem "sentry-delayed_job"
gem "sentry-rails"
gem "sentry-ruby"
gem "simpleidn"
gem "skylight"
gem "sprockets"
gem "sprockets-rails", require: "sprockets/railtie"
gem "state_machines-activerecord"
gem "strong_migrations"

gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

group :development, :test, :review do
  gem "bullet"
end

group :development, :test do
  gem "amazing_print"
  gem "capybara"
  gem "capybara-screenshot"
  gem "debug"
  gem "dotenv-rails"
  gem "knapsack"
  gem "parallel_tests"
  gem "pry"
  gem "rspec-rails"
  gem "rspec-sonarqube-formatter", require: false
  gem "rswag-specs"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
  gem "simplecov", require: false
end

group :development do
  gem "brakeman"
  gem "foreman"
  gem "i18n-debug"
  gem "listen"
  gem "rails-erd"
  gem "rubocop", require: false
  gem "ruby-lsp"
  gem "web-console"
end

group :test do
  gem "axe-core-capybara"
  gem "axe-core-rspec"
  gem "cuprite"
  gem "rack_session_access"
  gem "rspec-default_http_header"
  gem "shoulda-matchers"
  gem "site_prism"
  gem "webmock"
end

group :development, :test, :review, :sandbox, :staging do
  gem "factory_bot_rails"
  gem "faker"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
