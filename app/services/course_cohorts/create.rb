# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model

    validates :cohort, presence: true
    validates :course, presence: true

    attr_reader :course_cohort, :cohort, :course

    def initialize(cohort:, course:, training_dates:)
      @cohort = cohort
      @course = course
      @training_dates = training_dates
    end

    def call
      return if invalid?

      CourseCohort.transaction do
        @course_cohort = cohort.course_cohorts.find_or_create_by!(course:)

        create_milestones!
        create_course_cohort_providers!
        create_delivery_partnerships!
      end
    end

  private

    def create_course_cohort_providers!
      contract_years.each do |contract_year|
        ccp = @course_cohort.course_cohort_providers.find_or_initialize_by(lead_provider: contract_year.lead_provider)
        ccp.update!(contract_year.slice(:teacher_funding, :recruitment_target))
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

    def create_milestones!
      milestone_attributes = Array(course.cohort_configuration["milestones"])

      milestone_attributes.each do |attributes|
        create_milestone_from!(attributes:)
      end
    end

    def create_milestone_from!(attributes:)
      declaration_type = attributes["declaration_type"]
      milestone = @course_cohort.milestones.find_or_initialize_by(declaration_type:)

      if declaration_type == Milestone::COMPLETED && training_ends_at
        attributes.merge!(
          acceptance_window_start_date: training_ends_at - 2.months,
          acceptance_window_end_date: training_ends_at,
        )
      else
        attributes.merge!(acceptance_window_start_date: training_starts_at)
      end
      milestone.update!(attributes)
    end

    def training_starts_at
      @training_dates[:start]
    end

    def training_ends_at
      @training_dates[:end]
    end

    def contract_years
      @contract_years ||= @course.contract_years.includes(lead_provider: :delivery_partners).generic
    end
  end
end
