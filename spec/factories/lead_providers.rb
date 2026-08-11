FactoryBot.define do
  factory :lead_provider do
    transient do
      delivery_partner { nil }
      delivery_partners { Array.wrap(delivery_partner) }
    end

    name { Faker::Company.unique.name.gsub(",", "") }
    ecf_id { SecureRandom.uuid }
    hint { Faker::Lorem.sentence }
    email { Faker::Internet.email }

    after :create do |lead_provider, evaluator|
      partnerships = if evaluator.delivery_partners.is_a?(Hash)
                       evaluator.delivery_partners
                     elsif evaluator.delivery_partners&.any?
                       { create(:course_cohort, cohort: create(:cohort, :current)) => evaluator.delivery_partners }
                     else
                       {}
                     end

      partnerships.each do |course_cohort, delivery_partners|
        course_cohort = CourseCohort.find_by(cohort: course_cohort) || create(:course_cohort, cohort: course_cohort) if course_cohort.is_a?(Cohort)

        Array.wrap(delivery_partners).each do |delivery_partner|
          lead_provider.delivery_partnerships.create! delivery_partner:, course_cohort:
        end
      end
    end

    trait :with_courses do
      after :create do |lead_provider|
        create(:course, lead_provider:)
      end
    end
  end
end
