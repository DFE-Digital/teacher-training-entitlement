require "rspec/core/rake_task"

namespace :rswag do
  namespace :specs do
    desc "Generate Swagger YAML file for the webhooks from integration specs"
    RSpec::Core::RakeTask.new("swaggerize_webhooks") do |t|
      # Switch rswag to the webhooks document/root (see spec/swagger_helper.rb).
      ENV["RSWAG_WEBHOOKS"] = "1"

      t.pattern = ENV.fetch("WEBHOOKS_PATTERN", "spec/requests/webhooks/**/*_spec.rb")

      t.rspec_opts = if Rswag::Specs.config.rswag_dry_run
                       ["--format Rswag::Specs::SwaggerFormatter", "--dry-run", "--order defined"]
                     else
                       ["--format Rswag::Specs::SwaggerFormatter", "--order defined"]
                     end
    end
  end
end
