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

    def course_cohort
      ecf_id = read[:course_start_date]
      return if ecf_id.blank? || start_later?

      registerable_course_cohorts.find { _1.ecf_id == ecf_id }
    end

    def lead_provider
      id = read[:lead_provider_id]
      return if id.blank?

      (@lead_providers ||= {})[id] ||= LeadProvider.find_by(id:)
    end
  end
end
