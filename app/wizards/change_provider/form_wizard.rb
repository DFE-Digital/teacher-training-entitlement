module ChangeProvider
  class FormWizard
    include DfE::Wizard

    STEP_NAMES = %i[start choose-provider check-answers].freeze

    attr_reader :application

    def initialize(params:, session:, application:, action_type:)
      @application = application
      @action_type = action_type
      super(current_step: params[:step]&.to_sym || :start,
            current_step_params: params,
            state_store: DefaultStore.new(
              repository: DfE::Wizard::Repository::Session.new(
                session:,
                key: :"change_provider_#{application.ecf_id}",
              ),
            ))
    end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: self) do |graph|
        graph.root :start

        STEP_NAMES.each do |step_name|
          graph.add_node step_name, "ChangeProvider::Forms::#{step_name.to_s.parameterize.underscore.camelize}Form".constantize
        end

        STEP_NAMES.each_cons(2) do |from, to|
          graph.add_edge from:, to:
        end

        graph.add_node :"contact-us", ChangeProvider::Forms::NoOpForm

        graph.before_next_step do
          next_step_name
        end
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::DynamicRoutes.new(
        state_store:,
        path_builder: lambda { |step_id, _state_store, url_helpers, options|
          url_helpers.application_change_provider_path(application.ecf_id, step_id.to_s.dasherize, **options)
        },
      )
    end

    def step_strategy
      @step_strategy ||= ::ChangeProvider::StepStrategy.new(
        wizard: self,
        action_type: @action_type,
        application: @application,
      )
    end

    def next_step_name
      step_strategy.resolve.presence
    end
  end
end
