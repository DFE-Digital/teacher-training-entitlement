# frozen_string_literal: true

class RefreshUserTokenJob < ApplicationJob
  def perform(user)
    return if user.trn.present?
    return if user.refresh_token.blank?

    result = TeacherAuth::RefreshToken.new(user.refresh_token).call

    return unless result

    user.update!(
      refresh_token: result[:refresh_token],
      refresh_token_updated_at: Time.current,
    )
  end
end
