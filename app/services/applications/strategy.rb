module Applications
  class Strategy
    def self.for(application:, status:, reason:, admin_user:)
      case status
      when Application::WITHDRAWN
        Withdraw.new(application:, reason:, admin_user:)
      when Application::DEFERRED
        Defer.new(application:, reason:, admin_user:)
      when Application::ACCEPTED
        Resume.new(application:, course_cohort: application.course_cohort, admin_user:)
      end
    end
  end
end
