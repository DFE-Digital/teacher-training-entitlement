# frozen_string_literal: true

module Statements
  # Temporary placeholder for the finance statement calculations.
  #
  # A new calculation service is being written. Until it lands, this stub
  # returns 0 for every value the admin finance UI renders so the views and
  # components keep working.
  class Calculate
    def initialize(statement:)
      @statement = statement
    end

    def expected_starts = 0
    def expected_completed = 0
    def expected_total = 0
    def outstanding_starts = 0
    def outstanding_completed = 0
    def outstanding_total = 0
    def total_starts = 0
    def total_completed = 0
    def total_declarations = 0
    def expected_output_payment = 0
    def total_output_payment = 0
    def total_voided = 0
    def total_clawbacks = 0
    def total_adjustments = 0
    def total_service_fees = 0
    def total_payment = 0
    def total_retained = 0

    def funded_billable_count_for_type(_declaration_type) = 0
    def self_funded_billable_count_for_type(_declaration_type) = 0
    def output_payment_per_participant = 0
  end
end
