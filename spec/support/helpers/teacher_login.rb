module Helpers
  module TeacherLogin
    def teacher_sign_in(user: nil)
      user ||= create(:user)

      allow_any_instance_of(ApplicationController)
        .to receive(:session)
              .and_wrap_original do |original, *args|
        original.call(*args).tap { |session| session[:user_id] = user.id }
      end
    end
  end
end
