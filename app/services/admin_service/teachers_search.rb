class AdminService::TeachersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    return Teacher.all if q.blank?

    chain = default_scope

    if q.present?
      teachers = Teacher.arel_table

      chain = chain.where(teachers[:email].matches("%#{q}%"))
      chain = chain.or(default_scope.where(teachers[:full_name].matches("%#{q}%")))
      chain = chain.or(default_scope.where(teachers[:preferred_name].matches("%#{q}%")))
      chain = chain.or(default_scope.where(ecf_id: q))
      chain = chain.or(default_scope.where(applications: { ecf_id: q }))
      chain = chain.or(default_scope.where(teachers[:trn].matches("%#{q}%")))
      chain = chain.or(default_scope.where(applications: { institution_id: find_institutions_by_urn.pluck(:id) }))
    end

    chain.distinct
  end

private

  def find_institutions_by_urn
    Institution.where("institution_reference_number ILIKE ?", "%#{q}%")
  end

  def default_scope
    Teacher.left_joins(:applications).order(email: :asc)
  end
end
