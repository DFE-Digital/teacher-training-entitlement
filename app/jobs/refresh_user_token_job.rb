class RefreshUserTokenJob < ApplicationJob
  def perform(user)
    return unless user.requires_token_refresh?

    result = TeacherAuth::RefreshToken.new(user.refresh_token).call

    return unless result

    user.update!(
      refresh_token: result[:refresh_token],
      refresh_token_updated_at: Time.current,
    )
  end
end
