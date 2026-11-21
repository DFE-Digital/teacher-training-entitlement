module Registration
  module Steps
    module StateFundedSchool
      class ChooseSchool
        include Base

        OTHER = "other".freeze

        attribute :institution_name
        attribute :institution_id

        validates :institution_id, numericality: { only_integer: true }, unless: -> { institution_id.blank? || institution_id == OTHER }
        validates :institution_name, length: { maximum: 64 }

        validate :school_name_returns_results
        validate :institution_id_selected
        validate :institution_exists

        def self.permitted_params
          %i[institution_name institution_id]
        end

        def questions
          [
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
              default_value: selected_institution&.name_with_address,
            ),
          ]
        end

        def possible_institutions
          @possible_institutions ||= Institution
            .where(institutionable_type: %w[School LocalAuthority])
            .open_school_or_non_school
            .search(institution_name)
            .limit(10)
        end

      private

        def selected_institution
          return if institution_id.blank? || institution_id == OTHER

          @selected_institution ||= Institution.find_by(id: institution_id)
        end

        # This combination of fields is only used in the no-js fallback form:
        # institution_name is saved by the search done when JavaScript is disabled.
        def search_term_entered_in_no_js_fallback_form?
          state_store.read[:institution_name].present?
        end

        def school_name_returns_results
          return unless search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?

          errors.add(:institution_name, :no_results, name: institution_name)
        end

        def institution_exists
          return if institution_id.blank? || institution_id == OTHER || errors.include?(:institution_id)

          errors.add(:institution_id, :blank) unless selected_institution
        end

        def institution_id_selected
          # Allow the initial no-JS search (institution_name not yet saved)
          return if institution_name.present? && !search_term_entered_in_no_js_fallback_form?
          # Allow "other" for additional searches
          return if institution_id == OTHER

          errors.add(:institution_id, :blank) if institution_id.blank?
        end
      end
    end
  end
end
