require "rails_helper"

RSpec.describe Registrations::NpdCourseStartDateComponent, type: :component do
  it "renders the stored course cohort as the first option" do
    course_cohort = create(:course_cohort)
    wizard = instance_double(
      FormWizard,
      state_store: {
        "course_cohort_id" => course_cohort.id,
      },
    )
    step = instance_double(Forms::CustomViewStepForm, wizard:)
    form = GOVUKDesignSystemFormBuilder::FormBuilder.new(
      :course_start_date,
      Forms::CustomViewStepForm.new,
      vc_test_controller.view_context,
      {},
    )

    render_inline(described_class.new(step:, form:))

    expect(page).to have_text("When do you want to start the course?")
    expect(page).to have_text(course_cohort.name)
    expect(page).to have_field(course_cohort.name, with: "yes", type: :radio)
    expect(page).to have_field("I want to start at a later date", with: "later", type: :radio)
  end

  it "falls back to the next open reception course cohort" do
    course = create(:"tte-early-years")
    course_cohort = course.course_cohorts.last
    wizard = instance_double(FormWizard, state_store: {})
    step = instance_double(Forms::CustomViewStepForm, wizard:)
    form = GOVUKDesignSystemFormBuilder::FormBuilder.new(
      :course_start_date,
      Forms::CustomViewStepForm.new,
      vc_test_controller.view_context,
      {},
    )

    render_inline(described_class.new(step:, form:))

    expect(page).to have_field(course_cohort.name, with: "yes", type: :radio)
  end
end
