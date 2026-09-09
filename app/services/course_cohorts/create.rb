# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model

    validates :cohort, presence: true
    validates :course, presence: true

    attr_reader :course_cohort, :cohort, :course, :lead_providers, :training_dates, :milestone_types

    def initialize(cohort:, course:, lead_providers:, training_dates:, milestone_types: nil)
      @cohort = cohort
      @course = course
      @lead_providers = lead_providers
      @training_dates = training_dates
      @milestone_types = milestone_types
    end

    def call
      return if invalid?

      training_starts_at = training_dates[:start]
      training_ends_at = training_dates[:end]

      CourseCohort.transaction do
        @course_cohort = cohort.course_cohorts.find_or_create_by!(course:)

        create_milestones!(training_starts_at:, training_ends_at:)
        preload_delivery_partners

        lead_providers.each do |lead_provider, contract|
          course_cohort_provider = @course_cohort.course_cohort_providers.find_or_initialize_by(lead_provider:)
          course_cohort_provider.assign_attributes(
            lead_provider:,
            teacher_funding: contract["teacher_funding"].presence,
            recruitment_target: contract["recruitment_target"].presence,
          )
          course_cohort_provider.save!

          lead_provider.delivery_partners.each do |delivery_partner|
            @course_cohort.delivery_partnerships.find_or_create_by!(
              lead_provider:,
              delivery_partner:,
            )
          end
        end
      end
    end

  private

    def preload_delivery_partners
      return if lead_providers.empty?

      ActiveRecord::Associations::Preloader.new(
        records: lead_providers.map(&:first),
        associations: :delivery_partners,
      ).call
    end

    def create_milestones!(training_starts_at:, training_ends_at:)
      declaration_types(training_ends_at:).each do |declaration_type|
        milestone = @course_cohort.milestones.find_or_initialize_by(declaration_type:)
        milestone.assign_attributes(milestone_attributes(declaration_type, training_starts_at:, training_ends_at:))
        milestone.save!
      end
    end

    def declaration_types(training_ends_at:)
      return milestone_types if milestone_types.present?

      [Milestone::STARTED, training_ends_at && Milestone::COMPLETED].compact
    end

    def milestone_attributes(declaration_type, training_starts_at:, training_ends_at:)
      attributes = {
        declaration_type:,
        acceptance_window_start_date: training_starts_at,
      }

      if declaration_type == Milestone::COMPLETED && training_ends_at
        attributes.merge!(
          acceptance_window_start_date: training_ends_at - 2.months,
          acceptance_window_end_date: training_ends_at,
        )
      end

      attributes
    end
  end
end
