class AdminService::InstitutionsSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  def call
    base = Institution.includes(:institutionable).order(:name)
    return base if q.blank?

    name_matches = Institution.search(q)
    urn_matches = Institution.where(institution_reference_number: q)

    base.where(id: name_matches.select(:id)).or(base.where(id: urn_matches.select(:id)))
  end
end
