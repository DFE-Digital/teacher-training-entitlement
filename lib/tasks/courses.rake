namespace :courses do
  desc "Create courses"
  task create: :environment do
    Courses::Create.new(name: "TTE Early Years",
                        ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7",
                        identifier: "tte-early-years",
                        course_group: "reception",
                        description: "The Early Years development TTE course is aimed at teachers who have completed their induction and are currently teaching reception age children, or plan to in the future.",
                        short_code: "TTEEY").call
  end
end
