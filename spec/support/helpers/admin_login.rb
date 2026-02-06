module Helpers
  module AdminLogin
    def sign_in_as_admin
      sign_in_as(admin)
    end

    def sign_in_as_super_admin
      sign_in_as(super_admin)
    end

    def sign_in_as(admin_account)
      visit("/admin")
      expect(page).to have_current_path(sign_in_path)

      allow_any_instance_of(OtpCodeGenerator).to receive(:call).and_return(otp_code)
      page.fill_in "What’s your email address?", with: admin_account.email
      page.click_button "Sign in"
      expect(page).to have_current_path("/session/sign-in-code")

      page.fill_in "Enter your code", with: otp_code
      page.click_button "Sign in"

      expect(page).to have_current_path("/admin")
    end

    def otp_code
      "123456"
    end
  end
end
