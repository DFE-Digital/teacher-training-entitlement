module Registrations
  module Steps
    module ExcellenceInReception
      class ShareProvider
        include DfE::Wizard::Step

        TITLE = "Sharing your NPD information".freeze
        PARTIAL = "checkboxes".freeze
        ATTRIBUTE = :can_share_choices
        ANSWER_DISPLAY_NAME = "Can share choices".freeze
        MULTIPLE_ANSWERS = false
        DISPLAY_ON_CHECK_ANSWERS = false

        TEXTS = [
          {
            "text" => ["All the information you enter for your NPD registration will be shared with external organisations including auditors, evaluators, relevant bodies and training providers — this allows your provider to register you onto their course."],
            "text_class" => "govuk-body",
          },
          {
            "text" => ["For more information about who we share your data with read our <a href=\"https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers/privacy-information-education-providers-workforce-including-teachers#register-NPQ\">privacy notice</a>."],
            "text_class" => "govuk-body",
          },
          {
            "text" => ["If you do not agree to share your information you will not be able to progress with your NPD course."],
            "text_class" => "govuk-body",
          },
        ].freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "You must agree to share data with providers to continue" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [{ name: "Yes, I agree to share my information", value: "1" }]
        end
      end
    end
  end
end
