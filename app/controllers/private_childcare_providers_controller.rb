class PrivateChildcareProvidersController < PublicPagesController
  def index
    private_childcare_providers =
      PrivateChildcareProvider
        .joins(:institution)
        .where("institutions.institution_reference_number ILIKE ?", "%#{params[:name]}%")
        .limit(100)

    render(json: PrivateChildcareProviderSerializer.render(private_childcare_providers))
  end
end
