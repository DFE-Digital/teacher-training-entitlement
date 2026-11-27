module Registrations
  module Steps
    module ExcellenceInReception
      class ShareProvider < Shared::CheckBoxes
        with_title "Sharing your NPD information"
        with_attribute :can_share_choices
        with_answer_display_name "Can share choices"
        with_multiple_answers false
        with_display_on_check_answers false

        with_text "All the information you enter for your NPD registration will be shared with external organisations including auditors, evaluators, relevant bodies and training providers — this allows your provider to register you onto their course."
        with_text "For more information about who we share your data with read our <a href=\"https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers/privacy-information-education-providers-workforce-including-teachers#register-NPQ\">privacy notice</a>."
        with_text "If you do not agree to share your information you will not be able to progress with your NPD course."

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
