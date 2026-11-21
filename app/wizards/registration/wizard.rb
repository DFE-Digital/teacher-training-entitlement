module Registration
  class Wizard
    include DfE::Wizard

    class AuthenticationOrderError < StandardError; end

    STEPS = {
      sign_in: Steps::SignIn,
      course_start_date: Steps::CourseStartDate,
      cannot_register_yet: Steps::CannotRegisterYet,
      choose_your_provider: Steps::ChooseYourProvider,
      share_provider: Steps::ShareProvider,
      check_answers: Steps::CheckAnswers,
      registration_submitted: Steps::RegistrationSubmitted,
    }.freeze

    # The steps every journey starts with, in order. This is the only place that
    # sets where `sign_in` sits: move it to let teachers answer steps that do not
    # need a signed-in teacher first. `course_start_date` must stay last, it
    # branches to the rest of the journey.
    HEAD_STEPS = %i[sign_in course_start_date].freeze

    attr_reader :course, :current_user

    def self.for_session(course:, session:, **)
      state_store = StateStore.new(
        repository: DfE::Wizard::Repository::Session.new(session:, key: :registration, state_key: course.identifier),
      )

      new(course:, state_store:, **)
    end

    # `course` is set before `super`, as the steps processor is built during initialisation.
    def initialize(course:, state_store:, current_user: nil, **)
      @course = course
      @current_user = current_user
      state_store.course = course
      state_store.current_user = current_user

      super(state_store:, **)
    end

    def steps_processor
      @steps_processor ||= draw_steps_processor
    end

    def steps_operator
      @steps_operator ||= DfE::Wizard::StepsOperator::Builder.draw(wizard: self) do |builder|
        builder.on_step(:course_start_date, add: [Operations::NotifyForFutureRegistration])
        builder.on_step(:check_answers, use: [Operations::MarkSubmitted])
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

    # Step the teacher is sent to when they have to sign in.
    def sign_in_path
      resolve_step_path(:sign_in)
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

  private

    def draw_steps_processor
      graph = DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |dsl|
        STEPS.each do |step_name, step_class|
          dsl.add_node step_name, step_class, skip_when: (:signed_in? if step_name == :sign_in)
        end

        # A skipped root is not skipped by the gem, so the root is the first head step to show.
        dsl.conditional_root(potential_root: HEAD_STEPS.first(2)) do |state|
          HEAD_STEPS.find { |step_name| !(step_name == :sign_in && state.signed_in?) }
        end
        HEAD_STEPS.each_cons(2) { |from, to| dsl.add_edge from:, to: }
        dsl.add_conditional_edge from: :course_start_date, when: :start_later?, then: :cannot_register_yet, else: :choose_your_provider
        # Funding steps are drawn between these two steps by the course rule set.
        dsl.add_edge from: :choose_your_provider, to: :share_provider
        dsl.add_edge from: :share_provider, to: :check_answers
        dsl.add_edge from: :check_answers, to: :registration_submitted
      end

      ensure_authentication_before_steps_needing_it!(graph)
      graph
    end

    # A step that needs a signed-in teacher must not be reachable before `sign_in`.
    def ensure_authentication_before_steps_needing_it!(graph)
      early_steps = steps_before(graph.registry, :sign_in)
      offending = early_steps.select { |step_name| graph.find_step(step_name).requires_user }
      return if offending.empty?

      raise AuthenticationOrderError, "Steps needing a signed-in teacher come before sign_in: #{offending.join(', ')}"
    end

    # Every step from which `target` can be reached.
    def steps_before(registry, target)
      successors = Hash.new { |hash, key| hash[key] = [] }
      registry.edges.each { successors[_1.from] << _1.to }
      registry.conditional_edges.each { successors[_1.from].push(_1.then, _1.else) }
      registry.multiple_conditional_edges.each { |edge| successors[edge.from].push(*edge.branches.pluck(:then), edge.default) }

      registry.nodes.keys.select { |step_name| step_name != target && reaches?(successors, step_name, target) }
    end

    def reaches?(successors, from, target, visited = Set.new)
      return false unless visited.add?(from)

      successors[from].compact.any? { |to| to == target || reaches?(successors, to, target, visited) }
    end
  end
end
