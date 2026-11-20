module Registrations
  class StateStore
    def initialize(session:, key:)
      @session = session
      @key = key
    end

    def read
      ActiveSupport::HashWithIndifferentAccess.new(session[key] || {})
    end

    def [](key)
      read[key]
    end

    def write(attributes = {})
      session[key] = read.merge(attributes).to_h
    end

    def clear
      session.delete(key)
    end

  private

    attr_reader :session, :key
  end
end
