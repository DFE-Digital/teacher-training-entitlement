FactoryBot.define do
  factory :contract_year do
    lead_provider
    course

    trait :generic do
      academic_year { nil }
      recruitment_target { 3000 }
      teacher_funding { 650 }
      service_fee { 50 }
    end

    trait :course_details do
      academic_year { nil }
      secondary_form_url { "http://secondary_form.#{lead_provider.name}.com" }
      course_url { "http://#{course.name}.#{lead_provider.name}.com" }
    end
  end
end
