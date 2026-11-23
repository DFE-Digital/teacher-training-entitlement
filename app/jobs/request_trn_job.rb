class RequestTrnJob < ApplicationJob
  class RefreshTokenError < StandardError; end

  retry_on RefreshTokenError, wait: :polynomially_longer, attempts: 5

  def perform(teacher)
    return unless teacher.can_request_trn?

    # Get fresh access token
    tokens = TeacherAuth::RefreshToken.new(teacher.refresh_token).call

    if tokens == :invalid_token
      teacher.clear_auth_tokens!
      return
    end

    raise RefreshTokenError, "Failed to refresh token for teacher #{teacher.id}" unless tokens

    # Request TRN activation
    result = TeacherAuth::ActivateTrn.new(tokens[:access_token]).call

    # Update tokens regardless of activation result
    teacher_attrs = {
      refresh_token: tokens[:refresh_token],
      refresh_token_updated_at: Time.current,
      trn_requested_at: Time.current,
    }

    # If TRN returned immediately, update teacher and clear refresh token
    if result && result[:trn].present?
      teacher_attrs.merge!(
        trn: result[:trn],
        refresh_token: nil,
        refresh_token_updated_at: nil,
      )
    end

    teacher.update!(teacher_attrs)
  end
end
