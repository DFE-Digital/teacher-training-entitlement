class Admin::PolicyPeriodsController < AdminController
  def index
    @pagy, @policy_periods = pagy(PolicyPeriod.includes(:course_cohorts).order(start_date: :desc))
  end

  def show
    @policy_period = PolicyPeriod.find(params[:id])
    @course_cohorts = @policy_period
      .course_cohorts
      .includes(:course, :cohort, milestones: :statements)
      .sort_by { |course_cohort| [course_cohort.course.name, course_cohort.training_starts_at || Date.new(9999, 12, 31)] }
      .group_by(&:course)
    @contracts = Contract
      .joins(:course_cohorts)
      .where(course_cohorts: { policy_period_id: @policy_period.id })
      .includes(:lead_provider, course_cohorts: [:course, :cohort, { milestones: :statements }])
      .distinct
      .sort_by { |contract| [contract.lead_provider.name, contract.id] }
  end
end
