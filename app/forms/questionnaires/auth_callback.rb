module Questionnaires
  class AuthCallback < Base
    def skip_step?
      true
    end

    def next_step
      :course_start_date
    end

    def previous_step
      :start
    end
  end
end
