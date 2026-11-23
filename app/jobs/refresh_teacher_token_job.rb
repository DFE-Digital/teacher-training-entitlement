class RefreshTeacherTokenJob < ApplicationJob
  def perform(teacher)
    return unless teacher.requires_token_refresh?

    result = TeacherAuth::RefreshToken.new(teacher.refresh_token).call

    if result == :invalid_token
      teacher.clear_auth_tokens!
      return
    end

    return unless result

    teacher.update!(
      refresh_token: result[:refresh_token],
      refresh_token_updated_at: Time.current,
    )
  end
end
