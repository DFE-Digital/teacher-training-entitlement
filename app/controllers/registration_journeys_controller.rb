class RegistrationJourneysController < LoggedInController
  def show
    @registration_journey = RegistrationJourney.find_by!(slug: params[:journey_slug])
    @diagram = Registrations::MermaidDiagram.new(registration_journey: @registration_journey).call
  end
end
