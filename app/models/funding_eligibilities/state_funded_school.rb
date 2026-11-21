module FundingEligibilities
  class StateFundedSchool
    class MissingMandatoryInstitution < StandardError; end

    STEPS = {
      teacher_catchment: Registration::Steps::StateFundedSchool::TeacherCatchment,
      work_setting: Registration::Steps::StateFundedSchool::WorkSetting,
      choose_school: Registration::Steps::StateFundedSchool::ChooseSchool,
      possible_funding: Registration::Steps::StateFundedSchool::PossibleFunding,
      ineligible_for_funding: Registration::Steps::StateFundedSchool::IneligibleForFunding,
      funding_your_course: Registration::Steps::StateFundedSchool::FundingYourCourse,
    }.freeze

    def key
      STATE_FUNDED_SCHOOL
    end

    def name
      "State-funded school"
    end

    # Adds the steps of this rule set between the `entry` and `exit` steps.
    # `graph` is a Registration::RuleSetGraph.
    def draw(graph, entry:, exit:)
      store = graph.state_store

      STEPS.each { |step_name, step_class| graph.add_node(step_name, step_class) }

      graph.add_edge from: entry, to: :teacher_catchment
      graph.add_conditional_edge from: :teacher_catchment, when: -> { outside_england?(store) }, then: :ineligible_for_funding, else: :work_setting
      graph.add_conditional_edge from: :work_setting, when: -> { state_funded_setting?(store) }, then: :choose_school, else: :ineligible_for_funding
      graph.add_multiple_conditional_edges(
        from: :choose_school,
        branches: [
          { when: -> { no_institution_selected?(store) }, then: :choose_school },
          { when: -> { store.funding_eligibility_result == FUNDED_ELIGIBILITY_RESULT }, then: :possible_funding },
        ],
        default: :ineligible_for_funding,
      )
      graph.add_edge from: :possible_funding, to: exit
      graph.add_edge from: :ineligible_for_funding, to: :funding_your_course
      graph.add_edge from: :funding_your_course, to: exit
    end

    def check_answer_rows(presenter)
      store = presenter.state_store

      presenter.add_row("Workplace in England", store.teacher_catchment == Institution::ENGLAND_SUBDIVISION_CODE ? "Yes" : "No", :teacher_catchment)

      if store.work_setting.present?
        presenter.add_row("Work setting", I18n.t(store.work_setting, scope: "helpers.label.registration_wizard.work_setting_options"), :work_setting)
      end

      presenter.add_row("Workplace", store.institution.name_with_address, :choose_school) if store.institution

      if store.funding.present?
        presenter.add_row("Course funding", I18n.t(store.funding, scope: "helpers.label.registration_wizard.funding_options"), :funding_your_course)
      end
    end

    # `evaluate` takes a Registration::StateStore or, for the legacy journey, a
    # RegistrationQueryStore. Only the `institution:` keyword is specific to the
    # legacy journey, to evaluate a school that is not stored yet.
    def evaluate(query_store, institution: query_store.institution)
      return INELIGIBLE_SETTING if query_store.teacher_catchment == Institution::OTHER
      return NOT_IN_ENGLAND if institution && !institution.in_england?
      return PREVIOUSLY_FUNDED if previously_funded?(query_store)

      case query_store.work_setting
      when Institution::STATE_FUNDED_INSTITUTION then school_policy(institution)
      else INELIGIBLE_SETTING
      end
    end

    # Used by the legacy journey only (Questionnaires::ChooseSchool).
    def funded?(query_store, institution: query_store.institution)
      evaluate(query_store, institution:) == FUNDED_ELIGIBILITY_RESULT
    end

    def previously_funded?(query_store)
      accepted_applications(query_store).any?
    end

    def submission_attributes(query_store)
      result = evaluate(query_store)

      {
        funding_eligibility: result,
        # It is possible that the applicant had chosen a non-funded path and selected a funding choice
        # before going back a few steps and choosing a funded route. We should clear the funding choice
        # to nil here to reduce confusion
        funding_choice: result == FUNDED_ELIGIBILITY_RESULT ? nil : query_store.funding,
      }
    end

  private

    def outside_england?(store)
      store.teacher_catchment == Institution::OTHER
    end

    def state_funded_setting?(store)
      store.work_setting == Institution::STATE_FUNDED_INSTITUTION
    end

    def no_institution_selected?(store)
      store.institution.nil?
    end

    def school_policy(institution)
      raise MissingMandatoryInstitution if institution.nil?
      return INELIGIBLE_SETTING unless institution.eligible_establishment?

      FUNDED_ELIGIBILITY_RESULT
    end

    def users(query_store)
      user = query_store.current_user
      return User.where(trn: user.trn) if user&.trn.present?

      User.where(one_login_id: user&.one_login_id)
    end

    def accepted_applications(query_store)
      Application
        .where(user: users(query_store))
        .has_been_accepted
        .eligible_for_funding
        .where(funded_place: [nil, true])
    end
  end
end
