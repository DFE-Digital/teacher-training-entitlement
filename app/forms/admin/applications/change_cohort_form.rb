module Admin
  module Applications
    class ChangeCohortForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :application
      attribute :course_cohort_id, :integer
      attribute :override_declarations_check, :boolean, default: false

      validates_presence_of :course_cohort_id

      def course_cohort_options
        CourseCohort
          .joins(:cohort)
          .includes(:cohort)
          .where(course: application.course)
          .where.not(id: application.course_cohort_id)
          .order(cohort: { start_year: :asc })
      end

      def course_cohort
        @course_cohort ||= CourseCohort.find(course_cohort_id)
      end
    end
  end
end
