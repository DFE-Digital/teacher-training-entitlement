module Admin
  module CourseBuilder
    class Wizard
      include DfE::Wizard

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Linear.draw(self) do |linear|
          linear.add_step :create_cohort, Steps::CreateCohort
          linear.add_step :choose_course, Steps::ChooseCourse
          linear.add_step :create_course_cohort, Steps::CreateCourseCohort
          linear.add_step :create_milestone, Steps::CreateMilestone
          linear.add_step :check_answers, Steps::CheckAnswers, exit: true
        end
      end

      def route_strategy
        DfE::Wizard::RouteStrategy::DynamicRoutes.new(
          state_store:,
          path_builder: lambda { |step_id, _state_store, url_helpers, options|
            url_helpers.admin_course_builder_step_path(step: step_id.to_s.dasherize, **options)
          },
        )
      end

      def milestones
        Array(state_store.read.with_indifferent_access[:milestones])
      end
    end
  end
end
