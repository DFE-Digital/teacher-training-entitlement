module CourseCohorts
  class SetupForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment

    attribute :cohort
    attribute :course_id
    attribute :course_cohort
    attribute :training_starts_at, :date_or_hash
    attribute :training_ends_at, :date_or_hash
    attribute :lead_providers

    validates :cohort, presence: true
    validates :course_id, presence: true
    validate :valid_training_dates
    validate :at_least_one_lead_provider_selected

    def course_options
      @courses = Course.where.not(id: cohort.course_cohorts.select(:course_id)).order(:name)
    end

    def lead_provider_options
      @lead_providers = LeadProvider.all
    end

    def selected_lead_providers
      selected_providers.map do |id, contract|
        [LeadProvider.find(id), contract]
      end
    end

    def selected_course
      Course.find_by(id: course_id)
    end

    def training_dates
      {
        start: training_starts_at,
        end: training_ends_at,
      }
    end

    def add_service_errors(service_errors)
      service_errors.each do |error|
        error.add(:service, [error.attribute, error.message].join(" "))
      end
    end

  private

    def selected_providers
      lead_providers&.select { |_, attrs| attrs["id"].present? && attrs["id"] != "0" } || []
    end

    def valid_training_dates
      errors.add(:training_starts_at, "Enter a valid date") unless training_starts_at.is_a?(Date)
      errors.add(:training_ends_at, "Enter a valid date") if training_ends_at && !training_ends_at.is_a?(Date)
    end

    def at_least_one_lead_provider_selected
      return if selected_providers.present?

      errors.add(:lead_providers, "Select at least one lead provider")
    end
  end
end
