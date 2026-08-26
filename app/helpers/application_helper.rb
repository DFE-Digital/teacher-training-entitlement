module ApplicationHelper
  include Pagy::Frontend

  def default_page_title
    if request.path.match?(%r{\A/registration/})
      t("helpers.title.registration_wizard.service_title")
    else
      "National Professional Development(NPD)"
    end
  end

  def boolean_red_green_tag(bool, text = nil)
    text ||= bool ? "Yes" : "No"
    colour = bool ? "green" : "red"

    govuk_tag(text:, colour:)
  end

  def boolean_red_green_nil_tag(bool, text = nil)
    return "–" if bool.nil?

    boolean_red_green_tag(bool, text)
  end

  def boolean_tag(bool)
    bool ? "Yes" : "No"
  end

  def show_tracking_pixels?
    Rails.configuration.x.tracking_pixels_enabled && cookies["consented-to-cookies"] == "accept"
  end

  def show_otp_code_in_ui(current_env, admin)
    return unless current_env.in?(%w[development review staging]) && admin.present?

    tag.p("OTP code: #{admin.otp_hash}")
  end

  def application_status_badge(status)
    return nil unless status.presence

    govuk_tag(text: status.humanize, colour: application_status_colour(status))
  end

  def application_status_colour(status)
    {
      pending: "yellow",
      accepted: "green",
      started: "green",
      completed: "green",
      deferred: "red",
      rejected: "red",
      withdrawn: "red",
      reassigned: "red",
    }.fetch(status.to_sym, "grey")
  end

  def sentry_javascript_tag
    dsn = Sentry.configuration.dsn.public_key
    return if dsn.blank?

    javascript_include_tag "https://js.sentry-cdn.com/#{dsn}.min.js", crossorigin: "anonymous"
  end

  def join_with_commas(*args)
    args.select(&:present?).join(", ")
  end

  def one_login_home_url
    Rails.application.config.x.teacher_auth.one_login_home_url
  end

  def registration_step_display_value(registration_journey, answer_key, value)
    registration_step = registration_journey.registration_steps.find do |step|
      step.answer_key == answer_key.to_s
    end

    answer = registration_step&.answer_data&.find { |configured_answer| configured_answer["value"] == value.to_s }

    answer&.fetch("name") || value
  end
end
