class Admin::CourseBuilderController < AdminController
  before_action :ensure_super_admin

  def show
    render wizard.current_step_name
  end

  def create
    if wizard.save_current_step
      if adding_contract_financial_academic_year?
        save_contract_financial_academic_year!
        redirect_to admin_course_builder_path(step: wizard.current_step_name.to_s.dasherize) and return
      end

      redirect_to next_path and return unless wizard.current_step_name == :check_answers

      create_course!
    else
      render wizard.current_step_name, status: :unprocessable_content
    end
  end

private

  def create_course!
    service = Courses::Create.new(state_store:)

    service.call

    if service.errors.any?
      wizard.current_step.errors.copy!(service.errors)
      render wizard.current_step_name, status: :unprocessable_content
    else
      state_store.clear
      redirect_to admin_settings_path, notice: "Course created successfully"
    end
  end

  def state_store
    wizard.state_store
  end

  def wizard
    @wizard ||= Admin::CourseBuilder::Wizard.new(
      current_step: params.fetch(:step, "course-details").underscore.to_sym,
      current_step_params: params,
      state_store: Admin::CourseBuilder::StateStore.new(
        repository: DfE::Wizard::Repository::Session.new(session:, key: :admin_course_builder),
      ),
    )
  end

  def next_path
    return wizard.next_step_path if wizard.next_step

    admin_course_builder_path(step: wizard.current_step_name.to_s.dasherize)
  end

  def adding_contract_financial_academic_year?
    wizard.current_step_name == :contract_financials && params[:add_academic_year].present?
  end

  def save_contract_financial_academic_year!
    academic_years = wizard.current_step.academic_years
    academic_years << wizard.current_step.academic_year_to_add if wizard.current_step.academic_year_to_add.present?

    state_store.write(
      academic_year_to_add: nil,
      academic_years: academic_years.compact_blank.uniq,
    )
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      flash[:error] = "You must be a super admin to use the course builder"
      redirect_to admin_path
    end
  end
end
