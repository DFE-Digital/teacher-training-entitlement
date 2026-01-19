module Questionnaires
  class TeacherCatchment < Base
    attr_accessor :teacher_catchment, :teacher_catchment_country

    OPTIONS = %w[england another].freeze

    validates :teacher_catchment, presence: true, inclusion: { in: OPTIONS }

    def self.permitted_params
      %i[
        teacher_catchment
        teacher_catchment_country
      ]
    end

    def after_save
      wizard.store["teacher_catchment"] = teacher_catchment
    end

    def return_to_regular_flow_on_change?
      true
    end

    def next_step
      return :ineligible_for_funding if teacher_catchment == "another"

      :work_setting
    end

    def previous_step
      :choose_your_provider
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :teacher_catchment,
          options:,
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "england", label: "Yes", link_errors: true),
        build_option_struct(value: "another", label: "No"),
      ]
    end
  end
end
