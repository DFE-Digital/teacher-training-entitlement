# frozen_string_literal: true

all_schools = School.includes(:institution).limit(1000).to_a
lead_providers = LeadProvider.all.to_a

CourseCohort.includes(:course, :cohort, :schedule).find_each do |course_cohort|
  20.times do
    eligible_for_funding = Faker::Boolean.boolean(true_ratio: 0.6)
    funded_place = eligible_for_funding ? Faker::Boolean.boolean(true_ratio: 0.7) : false

    FactoryBot.create(
      :application,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      lead_provider: lead_providers.sample,
      school: all_schools.sample,
      course_cohort:,
      eligible_for_funding:,
      funded_place:,
    )
  end
end
