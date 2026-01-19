namespace :courses do
  desc "Update courses"
  task update: :environment do
    %w[
      reception
      leadership
      specialist
      support
      ehco
    ].each do |name|
      CourseGroup.find_or_create_by!(name:)
    end

    CourseService::DefinitionLoader.call
  end
end
