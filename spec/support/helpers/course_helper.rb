module Helpers
  module CourseHelper
    def course_milestone(course, declaration_type = "started")
      course.milestones.detect { _1.declaration_type == declaration_type.to_s }
    end
  end
end
