class BulkOperation::SubmitDeclarations < BulkOperation
  HEADERS = true
  FILE_HEADERS = %w[participant_id declaration_type declaration_date course_identifier delivery_partner_id lead_provider_name has_passed].freeze

  def run!
    result = {}
    ActiveRecord::Base.transaction do
      result = csv_rows.each_with_index.to_h do |row, index|
        row_number = index + 1
        [row_number, process_csv_row(row)]
      end
      update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def csv_rows
    file.open { CSV.read(_1, headers: true) }
  end

  def process_csv_row(row)
    participant = User.find_by(ecf_id: row["participant_id"])
    return "Participant not found" if participant.nil?

    lead_provider = LeadProvider.find_by(name: row["lead_provider_name"])
    return "Lead provider not found" if lead_provider.nil?

    course = Course.find_by(identifier: row["course_identifier"])
    application = Application
                    .joins(:application_lead_providers)
                    .joins(cohort: :course)
                    .where(user: participant, courses: { id: course })
                    .merge(ApplicationLeadProvider.current.where(lead_provider:))
                    .first

    service = Declarations::Create.new(
      application:,
      declaration_type: row["declaration_type"],
      declaration_date: row["declaration_date"],
      delivery_partner_id: row["delivery_partner_id"],
      has_passed: row["has_passed"].presence.try(:downcase),
    )

    if service.call
      "Declaration created successfully"
    else
      service.errors.full_messages.join(", ")
    end
  end
end
