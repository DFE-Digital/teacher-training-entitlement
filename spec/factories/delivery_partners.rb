FactoryBot.define do
  factory :delivery_partner do
    transient do
      # either an array or a hash of course cohort + array of lead providers
      lead_providers { Array.wrap(lead_provider) }
      lead_provider { nil }
    end

    ecf_id { SecureRandom.uuid }
    sequence(:name) { |n| "Delivery Partner #{n}" }

    after :create do |delivery_partner, evaluator|
      partnerships = if evaluator.lead_providers.is_a?(Hash)
                       evaluator.lead_providers
                     elsif evaluator.lead_providers&.any?
                       { create(:course_cohort, cohort: create(:cohort, :current)) => evaluator.lead_providers }
                     else
                       {}
                     end

      partnerships.each do |course_cohort, lead_providers|
        course_cohort = CourseCohort.find_by(cohort: course_cohort) || create(:course_cohort, cohort: course_cohort) if course_cohort.is_a?(Cohort)

        Array.wrap(lead_providers).each do |lead_provider|
          if LeadProvider.where(id: lead_provider.id).exists?
            delivery_partner.delivery_partnerships.create! lead_provider:, course_cohort:
          end
        end
      end
    end
  end
end
