module Admin
  module Applications
    class ChangeCohortForm
      include ActiveModel::Model
      include ActiveModel::Attributes
      attribute :id, :integer
      attribute :cohort_id, :integer
      attribute :override_declarations_check, :boolean, default: false

      validates_presence_of :cohort_id

      def cohort_options
        if application.schedule
          Cohort.joins(:schedules)
            .where(schedules: { course_group: application.course.course_group })
            .where.not(id: application.cohort.id)
            .distinct
            .order_by_oldest
        else
          Cohort.where.not(id: application.cohort.id).order_by_oldest
        end
      end

      def cohort
        @cohort ||= Cohort.find(cohort_id)
      end

      def application
        @application ||= Application.find(id)
      end
    end
  end
end
