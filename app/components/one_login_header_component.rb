# frozen_string_literal: true

class OneLoginHeaderComponent < ViewComponent::Base
  attr_reader :current_teacher

  def initialize(current_teacher:)
    @current_teacher = current_teacher
  end

  def sign_out_link
    helpers.button_to(
      "Sign out",
      helpers.sign_out_teacher_path,
      class: "one-login-header__nav__link",
      form_class: "one-login-header__nav__button-form",
      method: :delete,
    )
  end
end
