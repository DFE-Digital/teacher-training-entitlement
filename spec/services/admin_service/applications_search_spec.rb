# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminService::ApplicationsSearch do
  subject(:results) { described_class.new(q:, filters:).call }

  let(:filters) { {} }
  let(:user) { build(:user, preferred_name: "Rasmus Lerdorf") }
  let(:application) { create(:application, user:) }
  let(:started_milestone) { course_milestone(application.course, :started) }
  let(:completed_milestone) { course_milestone(application.course, :completed) }
  let(:declarations) do
    [
      create(:declaration, application:, declaration_type: :started, milestone: started_milestone),
      create(:declaration, application:, declaration_type: :completed, milestone: completed_milestone),
    ]
  end

  before do
    other_application = create(:application, user: create(:user, full_name: "Jane Doe"))
    create(:declaration, application: other_application, declaration_type: :started, milestone: started_milestone)
    create(:declaration, application: other_application, declaration_type: :completed, milestone: completed_milestone)
  end

  shared_examples "a search returning matching applications" do
    it { is_expected.to contain_exactly(application) }
  end

  context "when name matches" do
    let(:q) { application.user.full_name }

    it_behaves_like "a search returning matching applications"
  end

  context "when name partially matches" do
    let(:q) { application.user.full_name.split(" ").first }

    it_behaves_like "a search returning matching applications"
  end

  context "when preferred name matches" do
    let(:q) { application.user.preferred_name }

    it_behaves_like "a search returning matching applications"
  end

  context "when preferred name partially matches" do
    let(:q) { application.user.preferred_name.split(" ").first }

    it_behaves_like "a search returning matching applications"
  end

  context "when application ID matches" do
    let(:q) { application.ecf_id }

    it_behaves_like "a search returning matching applications"
  end

  context "when declaration ID matches" do
    let(:q) { declarations.first.ecf_id }

    it_behaves_like "a search returning matching applications"
  end

  context "when nothing matches" do
    let(:q) { "foobarbaz" }

    it { is_expected.to be_empty }
  end

  context "when query is blank" do
    let(:q) { nil }

    it { is_expected.to match_array(Application.all) }
  end

  context "when filters are provided" do
    let(:q) { nil }
    let(:filters) { { status: Application::ACCEPTED } }

    before do
      application.update!(status: Application::ACCEPTED)
    end

    it { is_expected.to contain_exactly(application) }
  end

  context "when blank filters are provided" do
    let(:q) { nil }
    let(:filters) { { status: "", work_setting: "" } }

    it { is_expected.to match_array(Application.all) }
  end

  context "when returning results" do
    let(:q) { nil }

    it "orders by created_at descending, then user_id descending" do
      newer_application = create(:application, created_at: 1.hour.from_now)

      expect(results.first).to eq(newer_application)
    end
  end
end
