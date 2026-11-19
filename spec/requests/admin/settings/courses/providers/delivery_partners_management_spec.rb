require "rails_helper"

RSpec.describe "Admin delivery partnership management", type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:course) { create(:course) }
  let!(:alpha_partnership) { create(:delivery_partnership, course:, lead_provider:, delivery_partner: alpha) }
  let!(:archived_partnership) { create(:delivery_partnership, course:, lead_provider:, delivery_partner: archived, archived_at: 1.day.ago) }
  let(:lead_provider) { create(:lead_provider) }
  let!(:zed) { create(:delivery_partner, name: "zed partner") }
  let!(:alpha) { create(:delivery_partner, name: "Alpha partner") }
  let!(:beta) { create(:delivery_partner, name: "beta partner") }
  let!(:archived) { create(:delivery_partner, name: "Archived partner") }
  let(:edit_path) { edit_admin_settings_course_provider_delivery_partnerships_path(course, lead_provider) }
  let(:update_path) { admin_settings_course_provider_delivery_partnerships_path(course, lead_provider) }
  let(:new_path) { new_admin_settings_course_provider_delivery_partner_path(course, lead_provider) }
  let(:create_path) { admin_settings_course_provider_delivery_partners_path(course, lead_provider) }
  let(:show_path) { admin_settings_course_provider_path(course, lead_provider) }
  let(:admin) { AdminUser.find_by(email: "test-admin@example.com") }

  before do
    create(:delivery_partnership, course:, lead_provider:, delivery_partner: zed)
    create(:contract_year, :generic, course:, lead_provider:)
    sign_in_as_admin(super_admin: true)
  end

  describe "show page" do
    it "has an Edit button" do
      get show_path

      expect(response.body).to include(edit_path)
    end
  end

  describe "edit form" do
    before { get edit_path }

    it "orders checked partners first then others, alphabetically ignoring case" do
      names = response.body.scan(/for="delivery-partner-[\w-]+">([^<]+)</).flatten

      expect(names).to eq(["Alpha partner", "zed partner", "Archived partner", "beta partner"])
    end

    it "checks only active partners" do
      expect(response.body.scan(/checked="checked"/).size).to eq(2)
    end

    it "renders a fieldset legend for each group" do
      expect(response.body).to include("Current delivery partners", "Other delivery partners")
      expect(response.body.scan("<legend").size).to eq(2)
    end

    it "shows add new and two save buttons" do
      expect(response.body.scan(/>save</).size).to eq(2)
      expect(response.body).to include("add new delivery partners")
    end
  end

  describe "save" do
    it "adds a new partnership" do
      patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id, alpha.id, beta.id] }

      expect(response).to redirect_to(show_path)
      expect(flash[:success]).to eq("1 delivery partner added, 0 removed")
      expect(DeliveryPartnership.active.where(course:, lead_provider:, delivery_partner: beta)).to exist
    end

    it "unarchives an archived partnership without a new row" do
      expect {
        patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id, alpha.id, archived.id] }
      }.not_to change(DeliveryPartnership, :count)
      expect(archived_partnership.reload).not_to be_archived
    end

    it "archives an unchecked partnership and keeps the partner" do
      expect {
        patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id] }
      }.not_to(change { [DeliveryPartnership.count, DeliveryPartner.count] })
      expect(alpha_partnership.reload).to be_archived
    end

    it "handles mixed changes" do
      patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id, beta.id] }

      expect(flash[:success]).to eq("1 delivery partner added, 1 removed")
    end

    it "does nothing when unchanged" do
      expect {
        patch update_path, params: { commit: "save", delivery_partner_ids: ["", zed.id, alpha.id] }
      }.not_to change(PaperTrail::Version, :count)
    end

    it "records versions with the admin as whodunnit", :versioning do
      patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id, beta.id] }
      patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id, beta.id, archived.id] }

      versions = PaperTrail::Version.where(item_type: "DeliveryPartnership").order(:id).last(3)
      expect(versions.map(&:event)).to eq(%w[create update update])
      expect(versions.map(&:whodunnit).uniq).to eq(["AdminUser #{admin.id}"])
    end

    it "blocks unchecking everything and preserves selections" do
      patch update_path, params: { commit: "save", delivery_partner_ids: [""] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select at least one delivery partner")
      expect(DeliveryPartnership.active.where(course:, lead_provider:).count).to eq(2)
    end

    it "ignores unknown ids mixed with valid ones" do
      patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id, 0, 999_999] }

      expect(response).to redirect_to(show_path)
      expect(alpha_partnership.reload).to be_archived
    end

    it "links the error summary to the first checkbox and describes the fieldset" do
      patch update_path, params: { commit: "save", delivery_partner_ids: [""] }

      expect(response.body).to include('href="#delivery-partner-ids"', 'id="delivery-partner-ids"', 'aria-describedby="delivery-partner-ids-error"', "Error: Edit delivery partners")
    end

    it "blocks a crafted request with only unknown ids" do
      patch update_path, params: { commit: "save", delivery_partner_ids: [0, 999_999] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(DeliveryPartnership.active.where(course:, lead_provider:).count).to eq(2)
    end

    it "does not touch other lead providers" do
      other = create(:delivery_partnership, course:, delivery_partner: alpha)

      patch update_path, params: { commit: "save", delivery_partner_ids: [zed.id] }

      expect(other.reload).not_to be_archived
    end
  end

  describe "add new delivery partners button" do
    it "goes straight to the new page without changes" do
      patch update_path, params: { commit: "add_new", delivery_partner_ids: [zed.id, alpha.id] }

      expect(response).to redirect_to(new_path)
    end

    it "goes straight to the new page with only a blank selection and no active partners" do
      DeliveryPartnership.where(course:, lead_provider:).delete_all
      patch update_path, params: { commit: "add_new", delivery_partner_ids: [""] }

      expect(response).to redirect_to(new_path)
    end

    context "with unsaved changes" do
      let(:params) { { delivery_partner_ids: [zed.id, beta.id] } }

      it "shows the warning without saving" do
        expect { patch update_path, params: params.merge(commit: "add_new") }.not_to change(PaperTrail::Version, :count)

        expect(response.body).to include("You have unsaved changes", "beta partner", "Alpha partner")
      end

      it "saves and continues" do
        patch update_path, params: params.merge(commit: "save_and_continue")

        expect(response).to redirect_to(new_path)
        expect(alpha_partnership.reload).to be_archived
      end

      it "returns to the form with errors if saving fails" do
        patch update_path, params: { commit: "save_and_continue", delivery_partner_ids: [""] }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Select at least one delivery partner")
      end

      it "discards and continues" do
        expect { patch update_path, params: params.merge(commit: "discard") }.not_to change(PaperTrail::Version, :count)

        expect(response).to redirect_to(new_path)
      end

      it "goes back with unsaved selections preserved" do
        patch update_path, params: params.merge(commit: "go_back")

        expect(response.body).to match(/id="delivery-partner-#{beta.id}"[^>]*checked="checked"/)
        expect(response.body).not_to match(/id="delivery-partner-#{alpha.id}"[^>]*checked="checked"/)
      end
    end
  end

  describe "provider not attached to the course" do
    let(:other_provider) { create(:lead_provider) }

    it "returns not found" do
      get edit_admin_settings_course_provider_delivery_partnerships_path(course, other_provider)
      expect(response).to have_http_status(:not_found)
      post admin_settings_course_provider_delivery_partners_path(course, other_provider), params: { commit: "save", names: %w[Y] }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "new delivery partners page" do
    it "labels inputs distinctly and describes errors" do
      post create_path, params: { commit: "save", names: ["Alpha partner", "Fresh"] }

      expect(response.body).to include("Delivery partner name 1", "Delivery partner name 2", 'aria-describedby="delivery-partner-name-0-error"', "Error: Add new delivery partners")
    end

    it "shows one input" do
      get new_path

      expect(response.body.scan('name="names[]"').size).to eq(1)
    end

    it "adds another input on add more, keeping values, saving nothing" do
      expect {
        post create_path, params: { commit: "add_more", names: %w[Typed] }
      }.not_to change(DeliveryPartner, :count)

      expect(response.body.scan('name="names[]"').size).to eq(2)
      expect(response.body).to include("Typed")
      expect(response.body).not_to include("govuk-error-message")
    end

    it "creates partners with partnerships and versions", :versioning do
      expect {
        post create_path, params: { commit: "save", names: [" One ", "Two", ""] }
      }.to change(DeliveryPartner, :count).by(2)

      expect(response).to redirect_to(show_path)
      new_ids = DeliveryPartner.where(name: %w[One Two]).ids
      versions = PaperTrail::Version.where(item_type: "DeliveryPartner", item_id: new_ids)
      expect(versions.pluck(:whodunnit)).to eq(["AdminUser #{admin.id}"] * 2)
      expect(PaperTrail::Version.where(item_type: "DeliveryPartnership").last.whodunnit).to eq("AdminUser #{admin.id}")
    end

    it "rejects existing names" do
      post create_path, params: { commit: "save", names: ["ALPHA PARTNER"] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("already exists")
    end

    it "rejects duplicates within the form" do
      expect { post create_path, params: { commit: "save", names: %w[Dup dup] } }.not_to change(DeliveryPartner, :count)

      expect(response.body).to include("entered more than once")
    end

    it "rejects a blank submit" do
      post create_path, params: { commit: "save", names: ["", ""] }

      expect(response.body).to include("Enter a delivery partner name")
    end
  end

  describe "authorisation" do
    before { sign_in_as_admin(email: "normal@example.com", super_admin: false) }

    it "blocks edit, update, new and create" do
      get edit_path
      expect(response).to redirect_to(sign_in_path)
      patch update_path, params: { commit: "save", delivery_partner_ids: [beta.id] }
      expect(response).to redirect_to(sign_in_path)
      get new_path
      expect(response).to redirect_to(sign_in_path)
      post create_path, params: { commit: "save", names: %w[X] }
      expect(response).to redirect_to(sign_in_path)
      expect(DeliveryPartner.where(name: "X")).not_to exist
    end
  end
end
