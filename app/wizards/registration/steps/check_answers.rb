module Registration
  module Steps
    class CheckAnswers
      include Base

      # Written by Operations::MarkSubmitted when the answers are submitted. Until
      # then the step is incomplete, which keeps registration_submitted unreachable.
      attribute :submitted, :boolean

      validates :submitted, inclusion: { in: [true] }

      def self.permitted_params
        []
      end
    end
  end
end
