module Applications
  module Validations
    module ApplicationNotSuperceded
      extend ActiveSupport::Concern

      included do
        validate :not_superceded
      end

      def not_superceded
        if application&.superceded_status?
          errors.add(:application, :application_was_superceded)
        end
      end
    end
  end
end
