module Registration
  module Steps
    class RegistrationSubmitted
      include Base

      # Only reachable once the answers were submitted and an application was created.
      validate :application_created

      def self.permitted_params
        []
      end

    private

      def application_created
        errors.add(:base, :not_submitted) unless state_store.submitted_application
      end
    end
  end
end
