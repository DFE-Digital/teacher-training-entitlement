class AdminService::UsersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    chain = default_scope

    if q.present?
      users = User.arel_table

      chain = chain.where(users[:email].matches("%#{q}%"))
      chain = chain.or(default_scope.where(users[:full_name].matches("%#{q}%")))
      chain = chain.or(default_scope.where(users[:preferred_name].matches("%#{q}%")))
      chain = chain.or(default_scope.where(ecf_id: q))
      chain = chain.or(default_scope.where(applications: { ecf_id: q }))
      chain = chain.or(default_scope.where(users[:trn].matches("%#{q}%")))
      chain = chain.or(default_scope.where(applications: { institution_id: find_institutions_by_urn.pluck(:id) }))
    end

    chain.distinct
  end

private

  def find_institutions_by_urn
    school_ids = School.where("urn ILIKE ?", "%#{q}%").joins(:institution).select("institutions.id")
    pcp_ids = PrivateChildcareProvider.where("provider_urn ILIKE ?", "%#{q}%").joins(:institution).select("institutions.id")
    Institution.where(id: school_ids).or(Institution.where(id: pcp_ids))
  end

  def default_scope
    User.left_joins(:applications).order(email: :asc)
  end
end
