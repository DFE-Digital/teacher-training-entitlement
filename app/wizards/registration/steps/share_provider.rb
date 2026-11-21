module Registration
  module Steps
    class ShareProvider
      include Base

      attribute :can_share_choices

      validates :can_share_choices, acceptance: { allow_nil: false }

      def self.permitted_params
        %i[can_share_choices]
      end

      def questions
        translations = I18n.t("helpers.hint.registration_wizard.can_share_choices", privacy_notice_url: PRIVACY_NOTICE_URL)

        translated_lines = translations.map do |line|
          line.include?("<a href") ? line.html_safe : line
        end

        [
          QuestionTypes::CheckBox.new(
            name: :can_share_choices,
            required: true,
            body: translated_lines,
          ),
        ]
      end
    end
  end
end
