class AdminService::WorkplaceSearch
  attr_reader :q

  def initialize(q:)
    @offset = 0
    @limit = 0
    @q = q
  end

  def count(_)
    scope.count
  end

  def offset(offset)
    @offset = offset
    self
  end

  def limit(limit)
    @limit = limit
    self
  end

  def each(&blk)
    results.each(&blk)
  end

private

  def scope
    @scope ||= begin
      base = Institution.includes(:institutionable).order(:name)

      if q.present?
        # Search by name/address using pg_search, or by URN
        name_matches = Institution.search_by_name(q)
        urn_matches = Institution.joins(
          "LEFT JOIN schools ON institutions.institutionable_type = 'School' AND institutions.institutionable_id = schools.id " \
          "LEFT JOIN private_childcare_providers ON institutions.institutionable_type = 'PrivateChildcareProvider' AND institutions.institutionable_id = private_childcare_providers.id"
        ).where("schools.urn = :q OR private_childcare_providers.provider_urn = :q", q:)

        base.where(id: name_matches.select(:id)).or(base.where(id: urn_matches.select(:id)))
      else
        base
      end
    end
  end

  def results
    scope.offset(@offset).limit(@limit).map(&:institutionable)
  end
end
