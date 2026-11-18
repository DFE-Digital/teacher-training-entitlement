class PrivateChildcareProvidersController < PublicPagesController
  def index
    private_childcare_providers =
      Institution
        .institution_type_private_childcare_provider
        .where("institution_reference_number ILIKE ?", "%#{params[:name]}%")
        .limit(100)

    render(json: PrivateChildcareProviderSerializer.render(private_childcare_providers))
  end
end
