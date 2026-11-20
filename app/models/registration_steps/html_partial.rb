module RegistrationSteps
  class HtmlPartial < RegistrationStep
    def set_html_partial!(partial_name:)
      return if partial_name.blank?

      config[:html_partial] = { partial_name: }

      update!(config:)
    end

    def partial_name
      config.dig("html_partial", "partial_name")
    end
  end
end
