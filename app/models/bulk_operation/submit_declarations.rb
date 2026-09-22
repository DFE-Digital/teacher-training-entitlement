class BulkOperation::SubmitDeclarations < BulkOperation
  HEADERS = true
  FILE_HEADERS = %w[lead_provider_name application_id declaration_type declaration_date delivery_partner_id secondary_delivery_partner_id has_passed].freeze

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
    application = Application.find_by(ecf_id: row["application_id"])
    return "Application not found" unless application

    lead_provider = LeadProvider.find_by(name: row["lead_provider_name"])
    return "Lead provider not found" unless lead_provider

    return "Lead provider is not assigned to application" if application.current_application_lead_provider&.lead_provider&.id != lead_provider.id

    service = Declarations::Create.new(
      application:,
      declaration_type: row["declaration_type"],
      declaration_date: row["declaration_date"],
      delivery_partner_id: row["delivery_partner_id"],
      secondary_delivery_partner_id: row["secondary_delivery_partner_id"],
      has_passed: row["has_passed"].presence&.downcase,
    )

    if service.call
      "Declaration created successfully"
    else
      service.errors.full_messages.join(", ")
    end
  end
end
