# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin/applications/change_funding_eligibilities/new", type: :view do
  let(:eligible_for_funding) { true }
  let(:form) { Admin::Applications::ChangeFundingEligibilityForm.new(application:, eligible_for_funding:) }
  let(:application) { build_stubbed(:application, :accepted) }

  subject { render }

  before do
    assign(:form, form)
    assign(:application, application)
  end

  it do
    aggregate_failures do
      expect(subject).to have_css("h1", text: application.user.full_name)
      expect(subject).to have_css(%(form[action="#{admin_applications_change_funding_eligibility_path(application)}"]), count: 1)
      expect(subject).to have_css(%(.govuk-form-group fieldset label), text: "Yes")
      expect(subject).to have_css(%(.govuk-form-group fieldset label), text: "No")
    end
  end

  context "when there are form errors" do
    let(:eligible_for_funding) { nil }

    it do
      aggregate_failures "form errors" do
        expect(form).not_to be_valid
        expect(subject).to have_css(".govuk-error-summary")
        expect(subject).to have_css(".govuk-error-message")
      end
    end
  end
end
