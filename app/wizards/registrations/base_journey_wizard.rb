require "dfe/wizard/steps_processor/base"

module Registrations
  class BaseJourneyWizard
    include DfE::Wizard

    attr_reader :course, :current_user

    def initialize(session:, course: nil, current_step: nil, current_step_params: {}, current_user: nil)
      @course = course
      @current_user = current_user
      repository = DfE::Wizard::Repository::Session.new(session:, key: :registrations)
      super(
        state_store: JourneyStateStore.new(repository:),
        current_step: current_step&.to_s&.underscore&.to_sym,
        current_step_params:,
      )
    end

    def journey_slug
      course&.identifier || Journeys::CourseSelectionWizard::JOURNEY_SLUG
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::DynamicRoutes.new(
        state_store:,
        path_builder: ->(step_id, _state, _helpers, _options) { "/registrations/#{journey_slug}/#{step_id.to_s.dasherize}" },
      )
    end

    def execute_services(execute_point:)
      current_step.public_send(execute_point) if current_step.respond_to?(execute_point)
    end

  protected

    def add_shared_wizard(shared_wizard)
      shared_wizard.add_to_graph
    end
  end
end
