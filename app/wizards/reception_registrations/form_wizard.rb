module ReceptionRegistrations
  class FormWizard
    include DfE::Wizard

    STEP_NAMES = %i[
      start
      closed
      course-start-date
      choose-your-course
      choose-your-provider
      teacher-catchment
      work-setting
      choose-school
      funding-your-course
      share-provider
      check-answers
    ].freeze

    attr_reader :application

    def initialize(params:, user:, session:, action_type:)
      @action_type = action_type
      @user = user
      super(current_step: params[:step]&.to_sym || :start,
            current_step_params: params,
            state_store: RegistrationState.new(
              repository: DfE::Wizard::Repository::Session.new(
                session:,
                key: :"registrations_#{user.id}",
              ),
            ))
    end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: self) do |graph|
        graph.root :start

        STEP_NAMES.each do |step_name|
          graph.add_node step_name, form_class_for(step_name)
        end

        STEP_NAMES.each_cons(2) do |from, to|
          graph.add_edge from:, to:
        end

        graph.add_node :"cannot-register-yet", ReceptionRegistrations::Forms::NoOpForm
        graph.add_node :"choose-a-tte-and-provider", ReceptionRegistrations::Forms::NoOpForm
        graph.add_node :"kind-of-nursery", ReceptionRegistrations::Forms::KindOfNurseryForm
        graph.add_node :"possible-funding", ReceptionRegistrations::Forms::NoOpForm
        graph.add_node :"ineligible-for-funding", ReceptionRegistrations::Forms::NoOpForm
        graph.add_node :"have-ofsted-urn", ReceptionRegistrations::Forms::NoOpForm

        graph.before_next_step do
          # TODO: Implement a after_step to decorate the state store
          # so this is a bit nicer
          if current_step_name == :'choose-school' && @action_type == :update
            write_state(
              funding_eligibility_status_code: funding_eligibility_service.funding_eligiblity_status_code,
              eligible_for_funding: funding_eligibility_service.eligible_for_funding?,
            )
          elsif current_step_name == :"work-setting" && @action_type == :update
            write_state(works_in_school: current_step.works_in_school?, works_in_childcare: current_step.works_in_childcare?)
          end
          next_step_name
        end
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::DynamicRoutes.new(
        state_store:,
        path_builder: lambda { |step_id, _state_store, url_helpers, options|
          url_helpers.reception_registration_path(step_id.to_s.dasherize, **options)
        },
      )
    end

    def step_strategy
      @step_strategy ||= ::ReceptionRegistrations::StepStrategy.new(
        wizard: self,
        action_type: @action_type,
        funding_eligibility_service:,
      )
    end

    def next_step_name
      step_strategy.resolve.presence
    end

  private

    def funding_eligibility_service
      @funding_eligibility_service ||= FundingEligibility.new(
        course: state_store.course,
        institution: state_store.selected_institution,
        inside_catchment: state_store.inside_catchment?,
        trn: @user.trn,
        get_an_identity_id: @user.get_an_identity_id,
        work_setting: state_store.work_setting,
        kind_of_nursery: state_store.kind_of_nursery,
        query_store: state_store,
      )
    end

    def form_class_for(step_name)
      "ReceptionRegistrations::Forms::#{step_name.to_s.parameterize.underscore.camelize}Form".constantize
    rescue StandardError
      ReceptionRegistrations::Forms::NoOpForm
    end
  end
end
