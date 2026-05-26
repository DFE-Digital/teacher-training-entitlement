require "rails_helper"

REGISTRATION_WIZARD_TEMPLATES = Dir[Rails.root.join("app/views/registration_wizard/*.html.erb")]
  .map { |f| File.basename(f, ".html.erb") }
  .reject { |t| t.start_with?("_") || t == "get_an_identity_callback" }
  .freeze

RSpec.describe "Registration wizard templates", :axe, type: :view do
  include RenderedHtmlAccessibilityHelper

  let(:store_stub) do
    {
      "national_insurance_number" => "AB123456C",
      "trn" => "1234567",
      "course_identifier" => "reception",
    }
  end

  # Stub answers for check_answers page
  let(:answers_stub) { [] }

  # Minimal stub for @wizard using OpenStruct for flexibility
  let(:wizard_stub) do
    OpenStruct.new(
      previous_step_path: "start",
      next_step_path: "check-answers",
      current_step: :teacher_catchment,
      course: course_stub,
      store: store_stub,
      answers: answers_stub,
    )
  end

  # Stub course for templates that need it
  let(:course_stub) do
    OpenStruct.new(
      identifier: "the-course",
      name: "The course",
    )
  end

  # Stub question for templates that render questions
  let(:question_stub) do
    OpenStruct.new(
      name: :example_question,
      question_text: "Example question",
      type: "radio_button_group",
      options: [OpenStruct.new(value: "yes", text: "Yes"), OpenStruct.new(value: "no", text: "No")],
      fieldset_styles: {},
    )
  end

  # Minimal stub for @form using OpenStruct
  let(:form_stub) do
    obj = OpenStruct.new(
      questions: [question_stub],
      to_key: nil,
      to_param: nil,
      persisted?: false,
      course: course_stub,
      message_template: "eligible_for_scholarship_funding",
      funding_amount: "£1000",
    )
    obj.define_singleton_method(:errors) { ActiveModel::Errors.new(obj) }
    obj.define_singleton_method(:model_name) { ActiveModel::Name.new(Object, nil, "RegistrationWizard") }
    obj
  end

  # Stub user for templates that need current_user
  let(:user_stub) do
    OpenStruct.new(
      trn: "1234567",
      email: "test@example.com",
    )
  end

  before do
    assign(:wizard, wizard_stub)
    assign(:form, form_stub)
    course = course_stub
    view.define_singleton_method(:course) { course }
    allow(view).to receive_messages(current_user: user_stub, registration_wizard_form_url: "/registration/test")
  end

  REGISTRATION_WIZARD_TEMPLATES.each do |template|
    describe template.to_s do
      # rubocop:disable RSpec/NoExpectationExample -- expectation is inside check_accessibility_of_html
      it "renders and is accessible" do
        wizard_stub.current_step = template.to_sym
        render template: "registration_wizard/#{template}", layout: "layouts/application"
        check_accessibility_of_html(rendered)
      end
      # rubocop:enable RSpec/NoExpectationExample
    end
  end
end
