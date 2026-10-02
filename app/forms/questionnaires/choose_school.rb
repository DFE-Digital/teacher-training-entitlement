module Questionnaires
  class ChooseSchool < Base
    attr_accessor :institution_name, :institution_id

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

    def next_step
      if no_institution_selected?
        :choose_school
      elsif ineligible_for_funding?
        :ineligible_for_funding
      else
        :possible_funding
      end
    end

    def previous_step
      :work_setting
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
          default_value: institution&.name_with_address,
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

    def no_institution_selected?
      institution_id == "other" || institution_id.blank?
    end

    def search_term_entered_in_no_js_fallback_form?
      # This combination of fields is only used in the no-js fallback form
      # institution_name will be set from the search term being entered into the search
      # field that is only visible when JS is disabled.
      wizard.store["institution_name"].present?
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

    delegate :ineligible_for_funding?, :institution, to: :query_store
  end
end
