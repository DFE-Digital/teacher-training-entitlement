class InstitutionsController < PublicPagesController
  def index
    schools = School
      .open
      .search_by_name(params[:name])

    local_authorities = Institution
      .search_by_name(params[:name])
      .where(institutionable_type: "LocalAuthority")
      .includes(:institutionable)
      .limit(100)
      .map(&:institutionable)

    render(json: InstitutionSerializer.render(schools + local_authorities))
  end
end
