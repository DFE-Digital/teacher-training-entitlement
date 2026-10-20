module Declarations
  module Validations
    module DeclarableValidation
      def application_is_declarable
        return if application.accepted_status? || application.started_status?

        errors.add(:application, :in_wrong_state)
      end
    end
  end
end
