# frozen_string_literal: true

class OneLoginHeaderComponent < ViewComponent::Base
  attr_reader :current_user

  def initialize(current_user:)
    @current_user = current_user
  end

  def sign_out_link
    helpers.button_to(
      "Sign out",
      helpers.sign_out_user_path,
      class: "one-login-header__nav__link",
      form_class: "one-login-header__nav__button-form",
      method: :delete,
    )
  end
end
