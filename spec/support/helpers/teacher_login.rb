module Helpers
  module TeacherLogin
    def teacher_sign_in(teacher: nil)
      teacher ||= create(:teacher)

      allow_any_instance_of(ApplicationController)
        .to receive(:session)
              .and_wrap_original do |original, *args|
        original.call(*args).tap { |session| session[:teacher_id] = teacher.id }
      end
    end
  end
end
