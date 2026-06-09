class RefreshUserTokenJob < ApplicationJob
  def perform(user)
    return unless user.requires_token_refresh?

    result = TeacherAuth::RefreshToken.new(user.refresh_token).call

    if result == :invalid_token
      user.clear_auth_tokens!
      return
    end

    return unless result

    user.update!(
      refresh_token: result[:refresh_token],
      refresh_token_updated_at: Time.current,
    )
  end
end
