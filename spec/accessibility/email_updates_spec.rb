require "rails_helper"

RSpec.describe "Email updates accessibility", :axe, type: :feature do
  describe "authenticated pages" do
    let(:user) { create(:user, :with_get_an_identity_id) }

    before do
      page.set_rack_session("user_id" => user.id)
    end

    it "new email updates page is accessible" do
      visit new_email_update_path
      expect(page).to be_axe_clean
    end
  end

  describe "public pages" do
    it "unsubscribe page is accessible" do
      visit unsubscribe_email_updates_path
      expect(page).to be_axe_clean
    end

    it "unsubscribed confirmation page is accessible" do
      visit unsubscribed_email_updates_path
      expect(page).to be_axe_clean
    end
  end
end
