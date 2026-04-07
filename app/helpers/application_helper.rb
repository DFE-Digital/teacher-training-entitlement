module ApplicationHelper
  include Pagy::Frontend

  def npq_registration_link
    if signed_in?
      if Feature.trn_required? && current_user.trn.blank?
        registration_wizard_show_path(:teacher_reference_number)
      else
        registration_wizard_show_path(:course_start_date)
      end
    else
      "/"
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

  def accepted?(application)
    application.accepted_status?
  end

  def pending?(application)
    application.pending_status?
  end

  def rejected?(application)
    application.rejected_status?
  end

  def application_course_start_date
    "autumn 2025"
  end

  def show_otp_code_in_ui(current_env, admin)
    return unless current_env.in?(%w[development review staging]) && admin.present?

    tag.p("OTP code: #{admin.otp_hash}")
  end

  def application_status_badge(status)
    return nil unless status.presence

    colour = {
      pending: "blue",
      accepted: "green",
      started: "green",
      deferred: "yellow",
      rejected: "red",
      withdrawn: "red",
    }.fetch(status.to_sym, "grey")

    govuk_tag(text: status.humanize, colour:)
  end

  def sentry_javascript_tag
    dsn = Sentry.configuration.dsn.public_key
    return if dsn.blank?

    javascript_include_tag "https://js.sentry-cdn.com/#{dsn}.min.js", crossorigin: "anonymous"
  end

  def join_with_commas(*args)
    args.select(&:present?).join(", ")
  end

  def trn_verified_badge(user)
    return unless user

    if user.trn_verified == false
      govuk_tag(text: "Not verified", colour: "red")
    else
      verified_method = if user.trn_auto_verified? || user.trn_lookup_status_found?
                          "automatically"
                        else
                          "manually"
                        end
      govuk_tag(text: "Verified", colour: "green") + " - #{verified_method}"
    end
  end

  def one_login_home_url
    ENV.fetch("ONE_LOGIN_HOME_URL")
  end
end
