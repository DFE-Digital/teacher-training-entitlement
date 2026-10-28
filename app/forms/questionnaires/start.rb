module Questionnaires
  class Start < Base
    def requirements_met?
      true
    end

    def next_step
      query_store.current_user.present? ? :course_start_date : :start
    end
  end
end
