module Questionnaires
  class ChooseSchool < Base
    include Helpers::Institution

    attr_accessor :institution_name, :institution_identifier

    validates :institution_identifier, format: { with: /\ASchool-\d{6,7}\z|\ALocalAuthority-\d+\z/, unless: -> { institution_identifier.blank? || institution_identifier == "other" } }
    validates :institution_name, length: { maximum: 64 }

    validate :validate_school_name_returns_results
    validate :validate_institution_identifier_selected

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    def next_step
      if institution_identifier == "other" || institution_identifier.blank?
        :choose_school
      elsif !institution(source: institution_identifier).in_england?
        :ineligible_for_funding
      else
        :possible_funding
      end
    end

    def previous_step
      return :kind_of_nursery if query_store.works_in_childcare?

      :work_setting
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :institution_identifier,
          locale_name: :choose_school,
          picker: :school,
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :institution_name,
            locale_name: :choose_school_search,
          ),
          default_value: selected_institution_display_value,
        ),
      ]
    end

    def selected_institution_display_value
      return nil if institution_identifier.blank?

      selected = institution(source: institution_identifier)
      return nil unless selected

      selected.name_with_address
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      schools = School
        .search_by_name(institution_name)
        .open
        .limit(10)

      local_authorities = LocalAuthority
        .search_by_name(institution_name)
        .limit(10)

      @possible_institutions = schools + local_authorities
    end

  private

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

    def validate_institution_identifier_selected
      # Allow initial no-JS search (institution_name not yet in wizard store)
      return if institution_name.present? && !search_term_entered_in_no_js_fallback_form?

      # Allow "other" selection for additional searches
      return if institution_identifier == "other"

      errors.add(:institution_identifier, :blank) if institution_identifier.blank?
    end
  end
end
