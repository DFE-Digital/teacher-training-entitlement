# frozen_string_literal: true

module Admin
  class StatementSummaryComponent < BaseComponent
    include StatementHelper

    attr_reader :calculator, :link_to_voids, :statement

    delegate :summary_rows,
             :expected_output_payment,
             :total_output_payment,
             :total_voided,
             :total_clawbacks,
             :total_adjustments,
             :total_payment,
             to: :calculator

    def initialize(statement:, link_to_voids: true)
      @calculator = ::Statements::Calculate.new(statement:)
      @link_to_voids = link_to_voids
      @statement = statement
    end

  private

    def label_with_hint(label, hint)
      tag.span(label) + tag.br + tag.span(hint, class: "govuk-hint govuk-!-font-size-16 govuk-!-margin-bottom-0")
    end
  end
end
