module Registrations
  module Courses
    class SendInclusivePracticeTeachers
      NAME = "Embedding inclusive practice".freeze
      JOURNEY_SLUG = "embedding-inclusive-practice".freeze
      IDENTIFIER = ::Course::SEND_INCLUSIVE_TEACHERS

      def self.course
        Course.find_by_identifier(IDENTIFIER)
      end
    end
  end
end
