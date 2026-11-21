module Registration
  class StateStore
    include DfE::Wizard::Core::StateStore

    # Set by the wizard: the course selected before the journey started.
    attr_accessor :course

    def start_later?
      read[:course_start_date] == Steps::CourseStartDate::LATER
    end

    def registerable_course_cohorts
      CourseCohort.registerable.where(course:).order(:training_starts_at)
    end

    def course_cohort
      return if read[:course_start_date].blank? || start_later?

      registerable_course_cohorts.find_by(ecf_id: read[:course_start_date])
    end

    def lead_provider
      LeadProvider.find_by(id: read[:lead_provider_id])
    end
  end
end
