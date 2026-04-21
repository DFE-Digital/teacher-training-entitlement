# frozen_string_literal: true

Sentry.init do |config|
  config.enabled_environments = %w[production sandbox staging review]
  config.dsn = config.enabled_environments.include?(Rails.env) ? ENV["SENTRY_DSN"] : "disabled"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.release = Rails.env.review? ? ENV["HOSTNAME"].match(/.*-(\d+)-/)[1] : ENV["COMMIT_SHA"]

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    next nil if event.transaction.match?(/healthcheck|up/i)

    if event.request
      event.request.data = filter.filter(event.request.data) if event.request.data
      event.request.headers = filter.filter(event.request.headers) if event.request.headers
      event.request.query_string = filter.filter(event.request.query_string) if event.request.query_string
    end
    event.user = filter.filter(event.user) if event.user
    event.extra = filter.filter(event.extra) if event.extra
    event.tags = filter.filter(event.tags) if event.tags
    event.contexts = filter.filter(event.contexts) if event.contexts
    event
  end

  config.enable_logs = true
  config.before_send_log = lambda do |event, _hint|
    # skip unimportant transactions
    next nil if event.transaction.match?(/healthcheck|up/i)

    event
  end

  config.excluded_exceptions += %w[
    SessionWizard::InvalidStep
  ]

  config.traces_sample_rate = Rails.env.production? ? 0.2 : 1.0
  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    name = transaction_context[:name]

    # Drop health checks entirely — they pollute your data
    next 0.0 if name.match?(/healthcheck|up/i)
    next 0.5 if Rails.env.review?

    # default for everything else
    0.2
  end
end
