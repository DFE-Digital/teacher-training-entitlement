# frozen_string_literal: true

module CourseCohorts
  class Update
    include ActiveModel::Model

    validates :course_cohort, presence: true

    attr_reader :course_cohort, :cohort, :course, :selected_lead_providers

    def initialize(course_cohort:, selected_lead_providers:)
      @course_cohort = course_cohort
      @selected_lead_providers = selected_lead_providers
      @course = course_cohort.course
      @cohort = course_cohort.cohort
    end

    def call
      return if invalid?

      CourseCohort.transaction do
        selected_lead_providers.each do |lead_provider, contract|
          ccp = @course_cohort.course_cohort_providers.find_by(lead_provider:)

          if ccp
            update_contract(ccp, contract)
          else
            create_contract(lead_provider, contract)
          end
        end
      end
    end

  private

    def create_contract(lead_provider, contract)
      @course_cohort.course_cohort_providers.create!(
        lead_provider:,
        teacher_funding: contract["teacher_funding"].presence,
        recruitment_target: contract["recruitment_target"].presence,
      )
      lead_provider.delivery_partners.each do |delivery_partner|
        @course_cohort.delivery_partnerships.create!(
          lead_provider:,
          delivery_partner:,
        )
      end
    end

    def update_contract(ccp, contract)
      ccp.update!(
        teacher_funding: contract["teacher_funding"].presence,
        recruitment_target: contract["recruitment_target"].presence,
      )
    end

    def delete_contract
      # cannot delete
    end
  end
end
