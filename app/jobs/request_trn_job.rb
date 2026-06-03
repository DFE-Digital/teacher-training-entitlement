class RequestTrnJob < ApplicationJob
  class RefreshTokenError < StandardError; end

  retry_on RefreshTokenError, wait: :polynomially_longer, attempts: 5

  def perform(application)
    user = application.user

    return unless user.requires_token_refresh?

    # Get fresh access token
    tokens = TeacherAuth::RefreshToken.new(user.refresh_token).call
    raise RefreshTokenError, "Failed to refresh token for user #{user.id}" unless tokens

    # Request TRN activation
    result = TeacherAuth::ActivateTrn.new(tokens[:access_token]).call

    # Update tokens regardless of activation result
    user_attrs = {
      refresh_token: tokens[:refresh_token],
      refresh_token_updated_at: Time.current,
      trn_requested_at: Time.current,
    }

    # If TRN returned immediately, update user and clear refresh token
    if result && result[:trn].present?
      user_attrs.merge!(
        trn: result[:trn],
        trn_verified: true,
        trn_auto_verified: true,
        refresh_token: nil,
        refresh_token_updated_at: nil,
      )
    end

    user.update!(user_attrs)
  end
end
