module Registration
  module Steps
    # The teacher already has an application for the chosen course and start date.
    # A dead end: the teacher goes back to pick another start date.
    class AlreadyApplied
      include Base

      validate :already_applied

      def self.permitted_params
        []
      end

    private

      def already_applied
        errors.add(:base, :not_applied) unless state_store.already_applied_for_course_cohort?
      end
    end
  end
end
