class Admin::Finance::StatementsController < AdminController
  include Admin::Cohortable

  before_action :set_statement, only: %i[show print_provider print_dfe_user]

  def index
    scope = Statement.includes(:lead_provider)
              .where(statement_params)
              .order(start_date: :desc)

    if @current_cohort
      scope = scope.joins(:course_cohorts).where(course_cohorts: { cohort_id: @current_cohort.id }).distinct
    elsif @current_academic_year
      scope = scope.joins(:course_cohorts).where(course_cohorts: { academic_year: @current_academic_year }).distinct
    end

    if scope.none?
      flash.now[:error] = "No statements matched all the filters, showing all statement periods instead"
      scope
    end

    @pagy, @statements = pagy(scope)
  end

  def show
    return unless @statement.authorising_for_payment?

    flash.now[:success_title] =
      t("admin.finance.statements.payment_authorisations.banner.title")

    flash.now[:success] =
      t("admin.finance.statements.payment_authorisations.banner.content",
        statement_marked_as_paid_at: @statement.marked_as_paid_at.strftime("%-I:%M%P on %-e %b %Y"))
  end

  def print_provider
    # empty method to appease rubocop
  end

  def print_dfe_user
    # empty method to appease rubocop
  end

private

  def set_statement
    @statement = Statement
                   .includes(
                     :declarations,
                     :milestones,
                     :course_cohorts,
                   )
                   .find(params[:id])
    @calculator = Statements::Calculate.new(statement: @statement)
  end

  def statement_params
    params.permit(:lead_provider_id, :payment_status, :statement, :output_fee)
      .tap { extract_output_fee _1 }
      .tap { extract_period _1 }
      .tap { extract_state _1 }
      .reject { |_k, v| v.blank? && v != false }
  end

  def extract_output_fee(params)
    params[:output_fee] = !!params.key?(:output_fee).to_s
  end

  def extract_period(params)
    return unless (period = params.delete(:statement))

    start_date, frequency = period.split("::")
    params[:frequency] = Statement::FREQUENCIES.fetch(frequency)
    params[:start_date] = Date.parse(start_date)
  end

  def extract_state(params)
    return unless (payment_status = params.delete(:payment_status))

    params[:state] = {
      "open" => %w[open],
      "payable" => %w[payable],
      "paid" => %w[paid],
    }.fetch(payment_status, [])
  end
end
