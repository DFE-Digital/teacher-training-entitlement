module Registration
  module Operations
    # Records on the teacher whether they asked to be told when later start
    # dates open for registration.
    class NotifyForFutureRegistration
      def initialize(step:, **)
        @step = step
      end

      def execute
        # Signed out when `sign_in` is moved after the start date step. The
        # flag is then not recorded: see ADR 001 §5 before moving `sign_in`.
        @step.wizard.current_user&.update!(
          notify_user_for_future_reg: @step.course_start_date == Steps::CourseStartDate::LATER,
        )

        { success: true }
      end

      def rollback; end
    end
  end
end
