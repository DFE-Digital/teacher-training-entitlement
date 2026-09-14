# frozen_string_literal: true

module Admin
  class StatementSummaryComponent < BaseComponent
    include StatementHelper
    include Rails.application.routes.url_helpers

    attr_reader :calculator, :link_to_voids, :statement

    delegate :summary_rows,
             :expected_output_payment,
             :total_output_payment,
             :total_voided,
             :total_clawbacks,
             :total_adjustments,
             :total_payment,
             to: :calculator

    def initialize(calculator:, statement:, link_to_voids: true)
      @calculator = calculator
      @link_to_voids = link_to_voids
      @statement = statement
    end

    def outstanding_link(row)
      link_to(
        row[:outstanding],
        outstanding_admin_finance_statement_path(statement, milestone: milestone(row)),
        class: "x-govuk-sub-navigation__link",
      )
    end

    def expected_link(row)
      link_to(
        row[:expected],
        expected_admin_finance_statement_path(statement, milestone: milestone(row)),
        class: "x-govuk-sub-navigation__link",
      )
    end

    def received_link(row)
      link_to(
        row[:received],
        received_admin_finance_statement_path(statement, milestone: milestone(row), funded: "yes"),
        class: "x-govuk-sub-navigation__link",
      )
    end

  private

    def milestone(row)
      row[:declaration_type] unless row[:declaration_type].downcase == "total"
    end

    def label_with_hint(label, hint)
      tag.span(label) + tag.br + tag.span(hint, class: "govuk-hint govuk-!-font-size-16 govuk-!-margin-bottom-0")
    end
  end
end
