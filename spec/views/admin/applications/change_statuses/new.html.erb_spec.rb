# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin/applications/change_statuses/new", type: :view do
  subject { render }

  before do
    assign(:application, application)
    assign(:form, form)
  end

  let(:application) { create(:application, :started) }
  let(:form) { Admin::Applications::ChangeStatusForm.new(id: application.id) }
  let(:form_path) { admin_applications_change_status_path(application) }

  it { is_expected.to have_css("h1", text: "Change status") }

  it { is_expected.to have_css(".govuk-inset-text p:first-of-type", text: application.user.id) }
  it { is_expected.to have_css(".govuk-inset-text p:last-of-type", text: "Started") }
  it { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }
  it { is_expected.to have_css(%(.govuk-form-group fieldset label), text: "Deferred") }
  it { is_expected.to have_css(%(.govuk-form-group fieldset label), text: "Withdrawn") }
  it { is_expected.to have_css("optgroup", count: 2) }
  it { is_expected.to have_css("optgroup option") }

  context "when there are form errors" do
    before { form.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
