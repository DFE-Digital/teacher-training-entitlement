module Questionnaires
  class ChooseYourProvider < Base
    attr_accessor :lead_provider_id

    validates :lead_provider_id, presence: true
    validate :validate_lead_provider_exists

    def self.permitted_params
      %i[
        lead_provider_id
      ]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :lead_provider_id,
          body: I18n.t("helpers.hint.registration_wizard.lead_provider_id", course_name: course.name).html_safe,
          style_options: { hint: nil },
          options:,
        ),
      ]
    end

    def next_step
      :teacher_catchment
    end

    def previous_step
      :course_start_date
    end

    def options
      enabled = enabled_providers.each_with_index.map do |provider, index|
        build_option_struct(
          value: provider.id,
          label: provider.name,
          hint: provider.hint,
          link_errors: index.zero?,
        )
      end

      disabled = disabled_providers.map do |provider|
        build_option_struct(
          value: provider.id,
          label: provider.name,
          hint: "This provider is not delivering the course start date you've selected - please go back if you wish to train with this provider",
          disabled: true,
        )
      end

      (enabled + disabled).sort_by(&:label)
    end

    def after_save
      wizard.store["lead_provider_id"] = lead_provider_id
    end

  private

    def enabled_providers
      @enabled_providers ||= course_cohort.lead_providers
    end

    def disabled_providers
      @disabled_providers ||= course.lead_providers - enabled_providers
    end

    def lead_provider
      enabled_providers.find_by(id: lead_provider_id)
    end

    delegate :course,
             :course_cohort,
             :inside_catchment?,
             to: :query_store

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end
