module Registration
  module Steps
    # Confirms the answers. Submitting it creates the application, see
    # Operations::CreateApplication.
    class CheckAnswers
      include Base

      def self.permitted_params
        []
      end
    end
  end
end
