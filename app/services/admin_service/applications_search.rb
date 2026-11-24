class AdminService::ApplicationsSearch
  attr_reader :filters, :query

  def initialize(q:, filters: {})
    @query = q
    @filters = filters.to_h.with_indifferent_access.compact_blank
  end

  def call
    application_scope
      .merge(search_scope)
      .order(created_at: :desc, teacher_id: :desc)
  end

private

  def application_scope
    Application
      .includes(
        :institution,
        :teacher,
        :lead_provider,
        :current_application_lead_provider,
        application_lead_providers: %i[lead_provider],
        course_cohort: %i[course cohort],
      )
      .merge(application_filter_scope)
  end

  def application_filter_scope
    return Application.all if status_filter.blank?

    Application.where(status: status_filter)
  end

  def status_filter
    @status_filter ||= Application::STATUSES.find { |status| status == filters[:status] }
  end

  def search_scope
    return Application.all if query.blank?

    scope.where(ecf_id: query)
      .or(scope.where(declarations: { ecf_id: query }))
      .or(scope.where("teachers.full_name ilike ?", "%#{query}%"))
      .or(scope.where("teachers.preferred_name ilike ?", "%#{query}%"))
      .distinct(:ecf_id)
  end

  def scope
    Application.left_joins(:teacher, :declarations).includes(:teacher, :declarations)
  end
end
