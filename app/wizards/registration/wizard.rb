module Registration
  class Wizard
    include DfE::Wizard

    class AuthenticationOrderError < StandardError; end
    class AttributeNameClash < StandardError; end

    STEPS = {
      sign_in: Steps::SignIn,
      course_start_date: Steps::CourseStartDate,
      cannot_register_yet: Steps::CannotRegisterYet,
      already_applied: Steps::AlreadyApplied,
      choose_your_provider: Steps::ChooseYourProvider,
      share_provider: Steps::ShareProvider,
      check_answers: Steps::CheckAnswers,
      registration_submitted: Steps::RegistrationSubmitted,
    }.freeze

    # The steps every journey starts with, in order. This is the only place that
    # sets where `sign_in` sits: move it to let teachers answer steps that do not
    # need a signed-in teacher first. `course_start_date` must stay last, it
    # branches to the rest of the journey, unless `sign_in` comes after it. Whichever
    # of the two comes last also checks that the teacher has not already applied for
    # the chosen start date (see `#draw_head_edges`).
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
        builder.on_step(:check_answers, add: [Operations::CreateApplication])
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

    # Shared steps and the steps of the course rule set.
    def step_names
      steps_processor.step_definitions.keys
    end

    def check_answers_rows
      CheckAnswersPresenter.new(self).call
    end

    # The answers are cleared once submitted, so the submitted page cannot rely
    # on the steps before it being valid: it only needs the created application.
    def valid_path_to?(target_step)
      return valid?(:registration_submitted) if target_step == :registration_submitted

      super
    end

    # First step of the current flow that the teacher has not completed yet.
    def first_incomplete_step
      step_id = root_step

      while valid?(step_id)
        following = steps_processor.next_step(step_id)
        # A step can lead back to itself, for example when no school was picked.
        return step_id if following.nil? || following == step_id || following == :registration_submitted

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
        # This repeats the `skip_when` rule of the sign_in node: keep both in sync.
        dsl.conditional_root(potential_root: HEAD_STEPS.first(2)) do |state|
          HEAD_STEPS.find { |step_name| !(step_name == :sign_in && state.signed_in?) }
        end
        draw_head_edges(dsl)
        FundingEligibilities.for_course(course).draw(RuleSetGraph.new(dsl, state_store:), entry: :choose_your_provider, exit: :share_provider)
        dsl.add_edge from: :share_provider, to: :check_answers
        dsl.add_edge from: :check_answers, to: :registration_submitted
      end

      ensure_unique_attribute_names!(graph)
      ensure_authentication_before_steps_needing_it!(graph)
      graph
    end

    # Edges between the head steps, and from the last one to the rest of the journey.
    # Whichever of `sign_in` and `course_start_date` is later knows both the teacher
    # and the start date, so it sends the teacher to `already_applied` when needed.
    def draw_head_edges(dsl)
      checking_step = %i[sign_in course_start_date].max_by { HEAD_STEPS.index(_1) || -1 }

      HEAD_STEPS.each_with_index do |step_name, index|
        following = HEAD_STEPS[index + 1] || :choose_your_provider
        branches = []
        branches << { when: :start_later?, then: :cannot_register_yet } if step_name == :course_start_date
        branches << { when: :already_applied_for_course_cohort?, then: :already_applied } if step_name == checking_step

        if branches.empty?
          dsl.add_edge(from: step_name, to: following)
        else
          dsl.add_multiple_conditional_edges(from: step_name, branches:, default: following)
        end
      end
    end

    # Answers are stored flat, so two steps with the same attribute would overwrite each other.
    def ensure_unique_attribute_names!(graph)
      clashes = graph.step_definitions.values.flat_map { |step_class| step_class.attribute_names.map(&:to_s) }.tally.select { |_, count| count > 1 }.keys
      return if clashes.empty?

      raise AttributeNameClash, "Step attribute names must be unique across the wizard: #{clashes.join(', ')}"
    end

    # Steps that need a signed-in teacher must only be reachable through `sign_in`.
    def ensure_authentication_before_steps_needing_it!(graph)
      raise AuthenticationOrderError, "sign_in is missing from HEAD_STEPS" unless HEAD_STEPS.include?(:sign_in)

      offending = reachable_without(graph.registry, HEAD_STEPS.first, :sign_in).select { |step_name| graph.find_step(step_name).requires_user }
      return if offending.empty?

      raise AuthenticationOrderError, "Steps needing a signed-in teacher can be reached before sign_in: #{offending.join(', ')}"
    end

    # Every step reachable from `root` without going through `blocked`.
    def reachable_without(registry, root, blocked)
      successors = Hash.new { |hash, key| hash[key] = [] }
      registry.edges.each { successors[_1.from] << _1.to }
      registry.conditional_edges.each { successors[_1.from].push(_1.then, _1.else) }
      registry.multiple_conditional_edges.each { |edge| successors[edge.from].push(*edge.branches.pluck(:then), edge.default) }

      visited = Set.new
      pending = [root]
      while (step_name = pending.pop)
        next if step_name == blocked || !visited.add?(step_name)

        pending.concat(successors[step_name].compact)
      end
      visited.to_a
    end
  end
end
