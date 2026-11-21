# A rule set that only exists in the test environment. It adds a single step
# between the entry and exit steps, to show that rule sets are pluggable.
module TestFundingEligibilities
  class ColourStep
    include Registration::Steps::Base

    attribute :favourite_colour

    validates :favourite_colour, presence: true

    def self.permitted_params
      %i[favourite_colour]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :favourite_colour,
          locale_name: :favourite_colour,
          options: [QuestionTypes::RadioOption.new(value: "red", label: "Red", link_errors: true)],
        ),
      ]
    end
  end

  class SingleStep
    KEY = "single_step".freeze

    def key
      KEY
    end

    def name
      "Single step"
    end

    def draw(graph, entry:, exit:)
      graph.add_node :favourite_colour, ColourStep
      graph.add_edge from: entry, to: :favourite_colour
      graph.add_edge from: :favourite_colour, to: exit
    end

    def evaluate(state_store)
      state_store.read[:favourite_colour] == "red" ? FundingEligibilities::FUNDED_ELIGIBILITY_RESULT : FundingEligibilities::INELIGIBLE_SETTING
    end

    def check_answer_rows(presenter)
      presenter.add_row("Favourite colour", presenter.state_store.read[:favourite_colour], :favourite_colour)
    end

    def submission_attributes(state_store)
      { funding_eligibility: evaluate(state_store), funding_choice: nil }
    end
  end
end

RSpec.shared_context "with a single step funding eligibility rule set" do
  before do
    allow(FundingEligibilities).to receive(:available).and_return([FundingEligibilities::StateFundedSchool.new, TestFundingEligibilities::SingleStep.new])
  end
end
