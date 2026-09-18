# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model

    validates :cohort, presence: true
    validates :course, presence: true

    attr_reader :course_cohort, :cohort, :course, :training_starts_at

    def initialize(cohort:, course:, training_starts_at:)
      @cohort = cohort
      @course = course
      @training_starts_at = training_starts_at
    end

    def call
      return if invalid?

      CourseCohort.transaction do
        find_or_create_course_cohort!
        create_course_cohort_providers!
        create_delivery_partnerships!
      end
    end

  private

    def find_or_create_course_cohort!
      @course_cohort = cohort.course_cohorts.find_or_create_by!(course:) do |course_cohort|
        course_cohort.training_starts_at = training_starts_at
      end
    end

    def create_course_cohort_providers!
      contract_years.each do |contract_year|
        course_cohort_provider = @course_cohort.course_cohort_providers.find_or_initialize_by(lead_provider: contract_year.lead_provider)
        course_cohort_provider.update!(contract_year.slice(:teacher_funding, :recruitment_target))
      end
    end

    def create_delivery_partnerships!
      contract_years.each do |contract_year|
        contract_year.lead_provider.delivery_partners.each do |delivery_partner|
          @course_cohort.delivery_partnerships.find_or_create_by!(
            lead_provider: contract_year.lead_provider,
            delivery_partner:,
          )
        end
      end
    end

    def contract_years
      @contract_years ||= @course.contract_years.includes(lead_provider: :delivery_partners).generic
    end

    def month_offset_between(from_date, to_date)
      (to_date.year * 12 + to_date.month) - (from_date.year * 12 + from_date.month)
    end
  end
end
