module Registration
  module Steps
    module StateFundedSchool
      class FundingYourCourse
        include Base

        VALID_FUNDING_OPTIONS = %w[school trust self another employer].freeze

        attribute :funding

        validates :funding, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

        def self.permitted_params
          %i[funding]
        end

        def questions
          [
            QuestionTypes::RadioButtonGroup.new(name: :funding, options:),
          ]
        end

        def options
          [
            option("school", link_errors: true),
            option("trust"),
            option("self"),
            option("another", hint: I18n.t("another", scope: "helpers.hint.registration_wizard.funding_options")),
          ]
        end

      private

        def option(value, **attrs)
          QuestionTypes::RadioOption.new(
            value:,
            label: I18n.t(value, scope: "helpers.label.registration_wizard.funding_options"),
            **attrs,
          )
        end
      end
    end
  end
end
