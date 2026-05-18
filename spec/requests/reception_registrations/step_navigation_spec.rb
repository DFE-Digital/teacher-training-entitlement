require "rails_helper"

RSpec.describe "Reception registration step navigation", type: :request do
  let(:user) { create(:user) }
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => {} }.with_indifferent_access }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  it "allows the first registration step without previous answers" do
    get reception_registration_path("course-start-date")

    expect(response).to render_template(:_course_start_date)
  end

  %w[
    choose-your-course
    choose-your-provider
    teacher-catchment
    work-setting
    choose-school
    possible-funding
    ineligible-for-funding
    funding-your-course
    share-provider
    check-answers
  ].each do |step|
    it "redirects #{step} to the start step without previous answers" do
      get reception_registration_path(step)

      expect(response).to redirect_to(reception_registration_path("start"))
    end
  end
end
