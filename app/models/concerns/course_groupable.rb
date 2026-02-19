module CourseGroupable
  extend ActiveSupport::Concern

  included do
    enum :course_group, {
      reception: "reception",
      send: "send",
    }, suffix: true
  end
end
