module Participants
  class Strategy
    WITHDRAWN = "withdrawn".freeze
    DEFERRED = "deferred".freeze
    ACTIVE = "active".freeze

    def self.for(application:, training_status:, reason:)
      case training_status
      when WITHDRAWN
        Withdraw.new(application:, reason:)
      when DEFERRED
        Defer.new(application:, reason:)
      when ACTIVE
        Resume.new(application:)
      end
    end
  end
end
