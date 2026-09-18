class Admin::Finance::Statements::OutstandingController < AdminController
  before_action :set_statement

  def show
    @applications_by_declaration_type = calculator.applications_by_declaration_type
  end

private

  def calculator
    @calculator ||= Statements::Calculate.new(statement: @statement, scope: :outstanding)
  end

  def set_statement
    @statement = Statement
                   .includes(
                     :declarations,
                     :milestones,
                     course_cohorts: %i[course milestones],
                   )
                   .find(params[:id])
  end
end
