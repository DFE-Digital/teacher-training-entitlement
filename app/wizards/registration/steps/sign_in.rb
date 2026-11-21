module Registration
  module Steps
    # Teacher Auth (GOV.UK One Login) sign in. The "Continue" button starts the
    # OmniAuth redirect, so this step is never submitted: it is complete once the
    # teacher is signed in, and is skipped from then on.
    class SignIn
      include Base

      self.requires_user = false

      validate :teacher_signed_in

      def self.permitted_params
        []
      end

    private

      def teacher_signed_in
        errors.add(:base, :not_signed_in) unless state_store.signed_in?
      end
    end
  end
end
