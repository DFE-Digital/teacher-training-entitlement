module Registration
  module Steps
    class ChooseYourProvider
      include Base

      attribute :lead_provider_id

      validates :lead_provider_id, presence: true
      validate :lead_provider_is_delivering_course_cohort, if: -> { lead_provider_id.present? }

      def self.permitted_params
        %i[lead_provider_id]
      end

      def questions
        [
          QuestionTypes::RadioButtonGroup.new(
            name: :lead_provider_id,
            body: I18n.t("helpers.hint.registration_wizard.lead_provider_id", course_name: wizard.course.name).html_safe,
            style_options: { hint: nil },
            options:,
          ),
        ]
      end

      def options
        (enabled_options + disabled_options).sort_by(&:label)
      end

    private

      def enabled_options
        enabled_providers.each_with_index.map do |provider, index|
          QuestionTypes::RadioOption.new(
            value: provider.id,
            label: provider.name,
            hint: provider.hint,
            link_errors: index.zero? || nil,
          )
        end
      end

      def disabled_options
        disabled_providers.map do |provider|
          QuestionTypes::RadioOption.new(
            value: provider.id,
            label: provider.name,
            hint: "This provider is not delivering the course start date you've selected - please go back if you wish to train with this provider",
            disabled: true,
          )
        end
      end

      def enabled_providers
        @enabled_providers ||= state_store.course_cohort&.lead_providers.to_a
      end

      def disabled_providers
        wizard.course.lead_providers - enabled_providers
      end

      def lead_provider_is_delivering_course_cohort
        errors.add(:lead_provider_id, :invalid) unless enabled_providers.map { _1.id.to_s }.include?(lead_provider_id.to_s)
      end
    end
  end
end
