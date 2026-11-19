require "rails_helper"

RSpec.describe Registrations::CourseStartDateComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:course) { create(:course, :npd_eirt) }
  let(:cohort) do
    create(
      :cohort,
      identifier: "later-registration-period",
      description: "Later registration period",
      registration_starts_at: 2.months.ago.to_date.beginning_of_month,
      registration_ends_at: 2.months.from_now.to_date,
    )
  end
  let!(:course_cohort) do
    create(
      :course_cohort,
      course:,
      cohort:,
      training_starts_at: 6.months.from_now.to_date,
    )
  end
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:form_object) do
    Class.new {
      include ActiveModel::Model
      attr_accessor :step_answer
    }.new
  end
  let(:form) { GOVUKDesignSystemFormBuilder::FormBuilder.new("registration_step", form_object, template, {}) }
  let(:router_step) { instance_double(Registrations::RouterStep) }

  it "offers registerable course cohorts after the first one and a later-date option" do
    expect(described_class.new(router_step:, form:).answer_options).to eq(
      [
        { value: course_cohort.ecf_id, display_value: cohort.name },
        { value: "later", display_value: "I want to start at a later date" },
      ],
    )
  end

  it "renders a radio button for each course start option" do
    render_inline(described_class.new(router_step:, form:))

    expect(page).to have_text("When do you want to start a course?")
    expect(page).to have_field("registration_step[step_answer]", type: "radio", with: course_cohort.ecf_id)
    expect(page).to have_field("registration_step[step_answer]", type: "radio", with: "later")
  end
end
