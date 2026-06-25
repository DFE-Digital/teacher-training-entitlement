FactoryBot.define do
  factory :provider_course_profile do
    course
    lead_provider
    url { "https://example.com/course-provider" }
  end
end
