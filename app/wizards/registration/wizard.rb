module Registration
  class Wizard
    include DfE::Wizard

    STEPS = {
      course_start_date: Steps::CourseStartDate,
      cannot_register_yet: Steps::CannotRegisterYet,
      choose_your_provider: Steps::ChooseYourProvider,
      share_provider: Steps::ShareProvider,
      check_answers: Steps::CheckAnswers,
      registration_submitted: Steps::RegistrationSubmitted,
    }.freeze

    attr_reader :course, :current_user

    # `course` is set before `super`, as the steps processor is built during initialisation.
    def initialize(course:, state_store:, current_user: nil, **)
      @course = course
      @current_user = current_user
      state_store.course = course

      super(state_store:, **)
    end

    def steps_processor
      @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        STEPS.each { |step_name, step_class| graph.add_node step_name, step_class }

        graph.root :course_start_date
        graph.add_conditional_edge from: :course_start_date, when: :start_later?, then: :cannot_register_yet, else: :choose_your_provider
        # Funding steps are drawn between these two steps by the course rule set.
        graph.add_edge from: :choose_your_provider, to: :share_provider
        graph.add_edge from: :share_provider, to: :check_answers
        graph.add_edge from: :check_answers, to: :registration_submitted
      end
    end

    def steps_operator
      @steps_operator ||= DfE::Wizard::StepsOperator::Builder.draw(wizard: self) do |builder|
        builder.on_step(:course_start_date, add: [Operations::NotifyForFutureRegistration])
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::DynamicRoutes.new(
        state_store:,
        path_builder: lambda { |step_id, _state_store, helpers, options|
          helpers.registration_step_path(course_identifier: course.identifier, step: step_id.to_s.dasherize, **options)
        },
      )
    end

    def step_names
      STEPS.keys
    end

    # First step of the current flow that the teacher has not completed yet.
    def first_incomplete_step
      step_id = root_step

      while valid?(step_id)
        following = steps_processor.next_step(step_id)
        return step_id if following.nil?

        step_id = following
      end

      step_id
    end
  end
end
