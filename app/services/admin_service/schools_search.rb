class AdminService::SchoolsSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    chain = default_scope

    if q.present?
      chain = chain.where("institutions.institution_reference_number = ?", q)
      chain = chain.or(default_scope.where("institutions.name ILIKE ?", "%#{q}%"))
    end

    chain
  end

private

  def default_scope
    School.joins(:institution).order("institutions.name ASC")
  end
end
