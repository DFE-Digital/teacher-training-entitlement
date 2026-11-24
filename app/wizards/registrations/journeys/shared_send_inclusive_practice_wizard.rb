module Registrations
  module Journeys
    class SharedSendInclusivePracticeWizard < BaseJourneyWizard
      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          check_course = add_node(
            graph,
            name: "You are checking funding eligbility for the #{journey_definition.name} NPD course",
            step_class: Registrations::StepDefinitions::Plain,
            texts: [
              {
                text: "If you want to check for a different course you can <a href=\"/registrations/#{Registrations::Courses::CourseSelection::JOURNEY_SLUG}/#{Registrations::Courses::CourseSelection::COURSES_STEP}\">change your course</a>",
                text_class: "govuk-hint",
              },
            ],
            answers: [
              { name: "Self-funded", value: "true", state_store_key: "self_funded", next_step_slug: "check-answers" },
            ],
          )

          teacher_catchment = add_node(
            graph,
            name: "Do you work in England?",
            slug: "teacher-catchment",
            answer_display_name: "Works in England?",
            state_store_key: "teacher_catchment",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: check_course.slug,
            required_answer_message: "Select 'Yes' if you work in England",
            services: [
              { class_name: Registrations::Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name, execute_point: :after_update },
            ],
            answers: [
              { name: "Yes", value: Questionnaires::TeacherCatchment::ENGLAND },
              { name: "No", value: Questionnaires::TeacherCatchment::NOT_ENGLAND },
            ],
          )

          check_answers = add_node(
            graph,
            name: "Check answers",
            slug: "check-answers",
            step_class: Registrations::StepDefinitions::CheckAnswers,
            redirect_path: "/applications",
            previous_step_slug: teacher_catchment.slug,
          )

          graph.root check_course.graph_id
          graph.add_multiple_conditional_edges(
            from: check_course.graph_id,
            branches: [
              {
                when: -> { state_store["self_funded"] == "true" },
                then: check_answers.graph_id,
                label: "Self-funded",
              },
            ],
            default: teacher_catchment.graph_id,
          )
          graph.add_edge from: teacher_catchment.graph_id, to: check_answers.graph_id
        end
      end
    end
  end
end
