module CourseCohorts
  class SetupForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment

    attribute :course
    attribute :course_id
    attribute :cohort
    attribute :cohort_id
    attribute :course_cohort
    attribute :training_starts_at, :date_or_hash

    validates :course, presence: true, unless: :cohort
    validates :course_id, presence: true, if: :cohort
    validates :cohort, presence: true, unless: :course
    validates :cohort_id, presence: true, if: :course
    validate :valid_training_starts_at

    def cohort_options
      @cohorts = Cohort.where.not(id: course.course_cohorts.select(:cohort_id)).order(registration_starts_at: :desc)
    end

    def course_options
      @courses = Course.where.not(id: cohort.course_cohorts.select(:course_id)).order(:name)
    end

    def selected_cohort
      cohort || Cohort.find_by(id: cohort_id)
    end

    def selected_course
      course || Course.find_by(id: course_id)
    end

    def add_service_errors(service_errors)
      service_errors.each do |error|
        error.add(:service, [error.attribute, error.message].join(" "))
      end
    end

  private

    def valid_training_starts_at
      errors.add(:training_starts_at, "Enter a valid date") unless training_starts_at.is_a?(Date)
    end
  end
end
