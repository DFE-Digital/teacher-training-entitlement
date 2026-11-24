module Registrations
  module Courses
    class SendInclusivePracticeLeaders
      NAME = "Embedding inclusive practice for leaders".freeze
      JOURNEY_SLUG = "embedding-inclusive-practice-for-leaders".freeze
      IDENTIFIER = ::Course::SEND_INCLUSIVE_LEADERS

      def self.course
        Course.find_by_identifier(IDENTIFIER)
      end
    end
  end
end
