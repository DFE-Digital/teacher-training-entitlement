module Applications
  module Concerns
    module StatusTransitionValidation
    private

      def validate_status_transition(application:, to:, error:, attribute: :application)
        return if application.blank?
        return if application.admin_user.present?
        return if application.can_transition_to?(to)

        errors.add(attribute, error)
      end
    end
  end
end
