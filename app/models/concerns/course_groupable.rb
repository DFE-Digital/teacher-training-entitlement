module CourseGroupable
  extend ActiveSupport::Concern

  included do
    enum :course_group, {
      npd: "npd",
      reception: "reception",
      send: "send",
    }, suffix: true
  end
end
