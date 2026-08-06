# frozen_string_literal: true

require "csv"

class AssuranceReports::CsvSerializer
  include StatementHelper

  def initialize(statement)
    @statement = statement
    @lead_provider_name = statement.lead_provider.name
    @period = statement_period(statement)
  end

  def filename
    "TTE-Declarations-#{@lead_provider_name.gsub(/\W/, "")}-#{@period.gsub(/\W/, '')}.csv"
  end

  def serialize
    CSV.generate do |csv|
      csv << csv_headers

      @statement.declarations.each do |record|
        csv << to_row(record, @statement.ecf_id)
      end
    end
  end

  def csv_headers
    [
      "Participant ID",
      "Participant Name",
      "TRN",
      "Course Identifier",
      "Schedule",
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
      "Statement Period",
      "Statement ID",
    ]
  end

private

  def to_row(declaration, statement_id)
    application = declaration.application
    user = application.user
    [
      user.ecf_id,
      user.full_name,
      user.trn,
      application.course.identifier,
      application.course_cohort.schedule.identifier,
      application.eligible_for_funding,
      application.funded_place,
      @lead_provider_name,
      application.institution.institution_reference_number,
      application.institution.name,
      application.status,
      state_change_reason(application),
      declaration.ecf_id,
      declaration.state,
      declaration.declaration_type,
      declaration.declaration_date.iso8601,
      declaration.created_at.iso8601,
      @period,
      statement_id,
    ]
  end

  def state_change_reason(application)
    event = application
              .state_changes
              .order(created_at: :desc)
              .first

    return unless event

    event.metadata.fetch("reason", nil)
  end
end
