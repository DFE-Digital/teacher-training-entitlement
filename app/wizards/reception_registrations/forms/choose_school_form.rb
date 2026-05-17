module ReceptionRegistrations
  module Forms
    class ChooseSchoolForm < StepForm
      attribute :institution_id, :string
      attribute :institution_name, :string

      validates :institution_id, numericality: { only_integer: true }, unless: -> { institution_id.blank? || institution_id == "other" }
      validates :institution_name, length: { maximum: 64 }

      validate :validate_school_name_returns_results
      validate :validate_institution_id_selected

      def self.permitted_params
        %i[
          institution_name
          institution_id
        ]
      end

      def question
        QuestionTypes::AutoCompleteInstitution.new(
          name: :institution_id,
          locale_name: :choose_school,
          picker: :school,
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :institution_name,
            locale_name: :choose_school_search,
          ),
          default_value: selected_institution_display_value,
        )
      end

      def selected_institution_display_value
        return nil if institution_id.blank?

        selected_institution&.name_with_address
      end

      def possible_institutions
        @possible_institutions ||= Institution
          .where(institutionable_type: %w[School LocalAuthority])
          .open_school_or_non_school
          .search_by_name(institution_name)
          .limit(10)
      end

    private

      def no_institution_selected?
        institution_id == "other" || institution_id.blank?
      end

      def selected_institution
        return nil if institution_id.blank? || institution_id == "other"

        @selected_institution ||= Institution.find(institution_id)
      end

      def search_term_entered_in_no_js_fallback_form?
        state_store["institution_name"].present? && no_institution_selected?
      end

      def validate_school_name_returns_results
        if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?
          errors.add(:institution_name, :no_results, name: institution_name)
        end
      end

      def validate_institution_id_selected
        # Allow initial no-JS search (institution_name not yet in wizard store)
        return if institution_name.present? && !search_term_entered_in_no_js_fallback_form?

        # Allow "other" selection for additional searches
        return if institution_id == "other"

        errors.add(:institution_id, :blank) if institution_id.blank?
      end
    end
  end
end
