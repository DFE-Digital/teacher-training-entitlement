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
      providers.each_with_index.map do |provider, index|
        build_option_struct(
          value: provider.id,
          label: provider.name,
          hint: provider.hint,
          link_errors: index.zero?,
        )
      end
    end

    def after_save
      wizard.store["lead_provider_id"] = lead_provider_id
    end

  private

    def providers
      LeadProvider.for(course:).alphabetical
    end

    def lead_provider
      providers.find_by(id: lead_provider_id)
    end

    delegate :course,
             :inside_catchment?,
             to: :query_store

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end
