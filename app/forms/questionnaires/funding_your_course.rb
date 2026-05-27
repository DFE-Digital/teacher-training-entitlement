module Questionnaires
  class FundingYourCourse < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another employer].freeze

    attr_accessor :funding

    validates :funding, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

    def self.permitted_params
      %i[
        funding
      ]
    end

    def next_step
      :share_provider
    end

    def previous_step
      :ineligible_for_funding
    end

    def course
      @course ||= wizard.query_store.course
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :funding,
          options:,
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "school", link_errors: true),
        build_option_struct(value: "trust"),
        build_option_struct(value: "self"),
        build_option_struct(value: "another"),
      ].freeze
    end
  end
end
