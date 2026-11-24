class RegistrationJourneysController < LoggedInController
  def show
    @journey_definition = Registrations::JourneyWizardFactory.build(params[:journey_slug])
    @diagram = Registrations::MermaidDiagram.new(journey_definition: @journey_definition).call
  end
end
