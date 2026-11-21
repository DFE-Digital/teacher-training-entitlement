module Registration
  class StateStore
    include DfE::Wizard::Core::StateStore

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
      @registerable_course_cohorts ||= CourseCohort.registerable.where(course:).includes(:cohort).order(:training_starts_at).to_a
    end

    def registerable_lead_providers
      LeadProvider.where(id: CourseCohortProvider.where(course_cohort: registerable_course_cohorts).select(:lead_provider_id)).alphabetical
    end

    def course_cohort
      ecf_id = read[:course_start_date]
      return if ecf_id.blank? || start_later?

      registerable_course_cohorts.find { _1.ecf_id == ecf_id }
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
