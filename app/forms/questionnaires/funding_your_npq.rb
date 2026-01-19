module Questionnaires
  class FundingYourNpq < Base
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
      # This is a placeholder that will hold the fund evaluation outcome
      # there are multiple possible origins `sad_paths`
      # :not_in_england, :not_eligible_for_funding, :participant_previously_funded
      wizard.query_store.funding_evaluation&.to_sym
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
        (build_option_struct(value: "trust") if works_in_school? && inside_catchment?),
        build_option_struct(value: "self"),
        build_option_struct(value: "another"),
      ].compact.freeze
    end

    delegate :works_in_school?, :inside_catchment?, to: :query_store
  end
end
