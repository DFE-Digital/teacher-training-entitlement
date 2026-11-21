module Registration
  # The course picked on the course selector page.
  class CourseSelection
    include ActiveModel::Model

    attr_accessor :course_identifier

    validates :course_identifier, presence: true
  end
end
