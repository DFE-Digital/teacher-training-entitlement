class Admin::Finance::StatementsController < AdminController
  include Admin::Cohortable

  before_action :set_statement, except: :index

  def index
    scope = Statement.includes(:lead_provider)
              .where(statement_params)
              .order(start_date: :desc)

    if @current_cohort
      scope = scope.joins(:course_cohorts)
                .where(course_cohorts: { cohort_id: @current_cohort.id })
                .distinct
    elsif @current_academic_year
      scope = scope
                .where(academic_year: @current_academic_year)
                .distinct
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

  def received
    @declarations = @statement.declarations.includes(:course_cohort, application: :user)
    funded_place = if params[:funded].blank? || params[:funded].downcase == "all"
                     nil
                   elsif params[:funded].downcase == "yes"
                     [true]
                   else
                     [nil, false]
                   end

    state = if params[:status].blank? || params[:status].downcase == "all"
              nil
            else
              params[:status].downcase
            end

    declaration_type = params[:milestone].presence&.downcase
    if funded_place
      @declarations.merge!(
        Declaration.joins(:application)
          .where(application: { funded_place: }),
      )
    end

    if state
      @declarations.merge!(Declaration.where(state:))
    end

    if declaration_type
      @declarations.merge!(Declaration.where(declaration_type:))
    end

    @name = @declarations.size
  end

  def outstanding
    @grouping = @calculator.outstanding
    @name = @grouping.values.flatten.size
  end

  def expected
    @grouping = @calculator.expected
    @name = @grouping.values.flatten.size
  end

private

  def set_statement
    @statement = Statement
                   .includes(
                     :declarations,
                     :milestones,
                     course_cohorts: %i[course milestones],
                   )
                   .find(params[:id])
    @calculator = Statements::Calculate.new(statement: @statement)
  end

  def statement_params
    params.permit(:lead_provider_id, :payment_status, :statement, :output_fee, :academic_year, :start_date, :frequency)
      .tap { extract_output_fee _1 }
      .tap { extract_period _1 }
      .tap { extract_state _1 }
      .reject { |_k, v| v.blank? && v != false }
  end

  def extract_output_fee(params)
    params[:output_fee] = !!params.key?(:output_fee).to_s
  end

  def extract_period(params)
    return if (period = params.delete(:statement)).blank?

    start_date, frequency = period.split("::")
    params[:frequency] = frequency if Statement::FREQUENCIES.keys.include?(frequency)
    params[:start_date] = parsed_date(start_date)
  end

  def parsed_date(date)
    Date.parse(date)
  rescue StandardError
    nil
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
