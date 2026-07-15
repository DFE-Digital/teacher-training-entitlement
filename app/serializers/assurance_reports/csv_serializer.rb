# frozen_string_literal: true

require "csv"

class AssuranceReports::CsvSerializer
  include StatementHelper

  def initialize(scope, statement)
    self.scope = scope
    self.statement = statement
  end

  def filename
    "TTE-Declarations-#{lead_provider.name.gsub(/\W/, '')}-Cohort#{cohort.name}-#{statement_name(statement).gsub(/\W/, '')}.csv"
  end

  def serialize
    CSV.generate do |csv|
      csv << csv_headers

      scope.each do |record|
        csv << to_row(record)
      end
    end
  end

  def csv_headers
    [
      "Participant ID",
      "Participant Name",
      "TRN",
      "Course Identifier",
      "Cohort",
      "Eligible For Funding",
      "Funded place",
      "Lead Provider Name",
      "School Urn",
      "School Name",
      "Status",
      "Status Reason",
      "Declaration ID",
      "Declaration Status",
      "Declaration Type",
      "Declaration Date",
      "Declaration Created At",
      "Statement Name",
      "Statement ID",
    ].compact
  end

private

  attr_accessor :scope, :statement

  delegate :cohort, :lead_provider, to: :statement

  def to_row(record)
    [
      record.participant_id,
      record.participant_name,
      record.trn,
      record.application_course_identifier,
      record.cohort_identifier,
      record.eligible_for_funding,
      record.funded_place,
      record.lead_provider_name,
      record.school_urn,
      record.school_name,
      record.status,
      record.status_reason,
      record.declaration_id,
      record.declaration_status,
      record.declaration_type,
      record.declaration_date.iso8601,
      record.declaration_created_at.iso8601,
      statement_name(statement),
      record.statement_id,
    ]
  end
end
