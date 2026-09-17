class Admin::Finance::Statements::ExpectedController < AdminController
  before_action :set_statement

  def show
    @applications_by_declaration_type = calculator.applications_by_declaration_type
  end

private

  def calculator
    @calculator ||= Statements::Calculate.new(statement: @statement, scope: :expected)
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
