module Admin
  module Applications
    class ChangeCohortForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :application
      attribute :cohort_id, :integer
      attribute :override_declarations_check, :boolean, default: false

      validates_presence_of :cohort_id

      def cohort_options
        application
          .course
          .cohorts
          .where.not(id: application.cohort_id)
          .order(start_year: :asc)
      end

      def cohort
        @cohort ||= Cohort.find(cohort_id)
      end
    end
  end
end
