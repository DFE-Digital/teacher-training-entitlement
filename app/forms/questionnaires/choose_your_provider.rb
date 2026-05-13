module Questionnaires
  class ChooseYourProvider < Base
    NOT_CHOSEN = "not_chosen".freeze

    attr_accessor :lead_provider_id

    validates :lead_provider_id, presence: true
    validate :validate_lead_provider_exists, unless: :not_chosen_provider?

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
      return :choose_a_tte_and_provider if not_chosen_provider?

      :teacher_catchment
    end

    def previous_step
      :choose_your_course
    end

    def options
      providers.each_with_index.map { |provider, index|
        build_option_struct(
          value: provider.id,
          label: provider.name,
          hint: provider.hint,
          link_errors: index.zero?,
        )
      } + [
        build_option_struct(
          value: NOT_CHOSEN,
          label: I18n.t("helpers.label.registration_wizard.lead_provider_id_options.not_chosen"),
          divider: true,
        ),
      ]
    end

    def after_save
      wizard.store["lead_provider_id"] = lead_provider_id
    end

    def not_chosen_provider?
      lead_provider_id == NOT_CHOSEN
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
