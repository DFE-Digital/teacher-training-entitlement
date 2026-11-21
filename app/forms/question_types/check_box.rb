module QuestionTypes
  class CheckBox < Base
    attribute :checked_value, default: "1".freeze
    attribute :unchecked_value, default: "0".freeze
    attribute :required, default: false

    # Texts are looked up under `registration_wizard`, as the new journey scopes forms by step name.
    def label_text
      I18n.t("helpers.label.registration_wizard.#{name_locale_key}_options.#{checked_value}")
    end

    def title_locale_type
      :legend
    end

    def default_styles
      {
        legend: {
          size: "xl",
          tag: "h1",
          text: question_text,
        },
        hint: nil,
      }
    end
  end
end
