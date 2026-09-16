module CourseCohorts
  class SetupForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment

    attribute :cohort
    attribute :course_id
    attribute :course_cohort
    attribute :training_starts_at, :date_or_hash

    validates :cohort, presence: true
    validates :course_id, presence: true
    validate :valid_training_starts_at

    def course_options
      @courses = Course.where.not(id: cohort.course_cohorts.select(:course_id)).order(:name)
    end

    def selected_course
      Course.find_by(id: course_id)
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
