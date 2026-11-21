module Registration
  class StateStore
    include DfE::Wizard::Core::StateStore

    # Session key of the application created by the teacher's submission.
    SUBMITTED_APPLICATION_KEY = :submitted_application_id

    # Set by the wizard: the course selected before the journey started.
    attr_accessor :course

    # Set by the wizard: the signed-in teacher, if any.
    attr_accessor :current_user

    def signed_in?
      current_user.present?
    end

    def start_later?
      read[:course_start_date] == Steps::CourseStartDate::LATER
    end

    def registerable_course_cohorts
      @registerable_course_cohorts ||= CourseCohort.registerable.where(course:).includes(:cohort, :lead_providers).order(:training_starts_at).to_a
    end

    # The teacher's application for the chosen start date, whatever its status:
    # `applications(user_id, course_cohort_id)` is unique.
    def existing_application
      return if current_user.blank? || course_cohort.blank?

      # Only found applications are kept: a missing one may be created later in the request.
      @existing_applications ||= {}
      @existing_applications[[current_user.id, course_cohort.id]] ||=
        current_user.applications.includes(course_cohort: :cohort).find_by(course_cohort:)
    end

    def already_applied_for_course_cohort?
      existing_application.present?
    end

    def registerable_lead_providers
      LeadProvider.where(id: CourseCohortProvider.where(course_cohort: registerable_course_cohorts).select(:lead_provider_id)).alphabetical
    end

    def course_cohort
      ecf_id = read[:course_start_date]
      return if ecf_id.blank? || start_later?

      registerable_course_cohorts.find { _1.ecf_id == ecf_id }
    end

    # The application created when the answers were submitted. The answers are
    # cleared by then, so this is what tells the teacher has submitted. It no
    # longer counts once the teacher answers a step again.
    def submitted_application
      id = read[SUBMITTED_APPLICATION_KEY]
      return if id.blank? || current_user.blank?
      return if read.to_h.symbolize_keys.except(SUBMITTED_APPLICATION_KEY).values.any?(&:present?)

      current_user.applications.find_by(id:)
    end

    def teacher_catchment
      read[:teacher_catchment]
    end

    def work_setting
      read[:work_setting]
    end

    def funding
      read[:funding]
    end

    def institution
      id = read[:institution_id]
      return if id.blank? || id == Steps::StateFundedSchool::ChooseSchool::OTHER

      (@institutions ||= {})[id] ||= Institution.find(id)
    end

    # The result code of the course rule set. It is evaluated once per set of
    # answers, as it looks up the previously funded applications of the teacher.
    def funding_eligibility_result
      answers = read.to_h
      return @funding_eligibility_result if defined?(@funding_eligibility_result) && @funding_answers == answers

      @funding_answers = answers
      @funding_eligibility_result = FundingEligibilities.for_course(course).evaluate(self)
    end

    def lead_provider
      id = read[:lead_provider_id]
      return if id.blank?

      (@lead_providers ||= {})[id] ||= LeadProvider.find_by(id:)
    end
  end
end
