return if Statement.where(state: "payable").exists?

helpers = Class.new { include ActiveSupport::Testing::TimeHelpers }.new

LeadProvider.all.find_each do |lead_provider|
  statement_scope  = Statement.where(lead_provider:).order(deadline_date: :desc)
  latest_statement = statement_scope.with_output_fee.where("deadline_date <= ?", Time.zone.today).first

  next unless latest_statement

  # Mark past open statements (including latest output fee statement) as payable
  statement_scope.where(state: :open).where("deadline_date <= ?", latest_statement.deadline_date).find_each(&:prepare_to_freeze!)

  # Void some declarations on the previous paid output fee statement to create clawbacks on the latest statement
  helpers.travel_to latest_statement.deadline_date - 1.day do
    claw_back_from_statement = statement_scope.with_output_fee.where(state: :paid).where("deadline_date < ?", latest_statement.deadline_date).first
    next unless claw_back_from_statement

    claw_back_from_statement.declarations.where.not(state: "voided").limit(2).each do |declaration|
      errors = Declarations::Clawback.new(declaration:).tap(&:call).errors
      fail(errors.full_messages.join(", ")) if errors.any?
    end
  end
end

# Set mark_as_paid_at for payable statements from 2023-2025, and mark them as paid - to match production
Statement.where(state: "payable").where("start_date < ?", Date.new(2026, 1, 1)).find_each do |statement|
  helpers.travel_to statement.payment_date - 8.days do
    statement.mark_as_frozen!
  end
end
