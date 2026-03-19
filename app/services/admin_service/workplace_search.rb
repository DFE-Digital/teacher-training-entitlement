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
        name_matches = Institution.search_by_name(q)
        urn_matches = Institution.where(institution_reference_number: q)

        base.where(id: name_matches.select(:id)).or(base.where(id: urn_matches.select(:id)))
      else
        base
      end
    end
  end

  def results
    scope.offset(@offset).limit(@limit)
  end
end
