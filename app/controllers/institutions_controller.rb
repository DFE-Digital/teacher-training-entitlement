class InstitutionsController < PublicPagesController
  def index
    institutions = Institution
      .where(institutionable_type: %w[School LocalAuthority])
      .open_school_or_non_school
      .search(params[:name])

    render(json: InstitutionSerializer.render(institutions))
  end
end
