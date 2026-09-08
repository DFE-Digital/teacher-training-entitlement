# frozen_string_literal: true

module Admin
  class StatementSelectorComponent < BaseComponent
    StatementOption = Struct.new(:name, :value)

    include StatementHelper

    attr_reader :format_for_sidebar, :lead_provider_id, :selection, :cohort, :academic_year

    def initialize(selection, cohort: nil, academic_year: nil, format_for_sidebar: false)
      @selection = selection
      @lead_provider_id = selection[:lead_provider_id]
      @format_for_sidebar = format_for_sidebar
      @cohort = cohort
      @academic_year = academic_year
    end

    def grid_column_class
      format_for_sidebar ? "govuk-grid-column-full" : "govuk-grid-column-one-half"
    end

    def submit_button_text
      format_for_sidebar ? "View" : "Search"
    end

    def payment_status
      selection[:payment_status].presence
    end

    def output_fee
      selection.key?(:output_fee) ? selection[:output_fee] : "true"
    end

    def lead_providers
      LeadProvider.all.alphabetical
    end

    def statements
      scope = Statement.all.order(start_date: :desc)

      scope = scope.where(academic_year:) if academic_year
      scope = scope.includes(:course_cohorts).where(course_cohorts: { cohort: }).distinct if cohort
      scope = scope.where(lead_provider_id:) if lead_provider_id.present?

      options = [["All", ""]] + scope.map { [statement_name(_1), statement_options_value(_1)] }
      options.map { StatementOption.new(*_1) }.uniq(&:value)
    end

    def selected_statement
      selection[:statement].presence
    end
  end
end
