module Questionnaires
  # This is for choosing *public* childcare providers, these are stored alongside schools in the educationl_institutions
  # table as type School, therefore, we search and display identically to as we do for schools
  class ChooseChildcareProvider < Base
    attr_accessor :institution_name, :institution_id

    validates :institution_id, numericality: { only_integer: true }, unless: -> { institution_id.blank? || institution_id == "other" }
    validates :institution_name, length: { maximum: 64 }

    validate :validate_childcare_provider_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_id
      ]
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :institution_id,
          locale_name: :choose_childcare_provider,
          picker: :nursery,
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :institution_name,
            locale_name: :choose_childcare_provider_search,
          ),
        ),
      ]
    end

    def next_step
      if institution_id == "other" || institution_id.blank?
        :choose_childcare_provider
      elsif !selected_institution.in_england? # Right now this is always true when it shouldn't be
        :childcare_provider_not_in_england
      else
        :choose_your_npq
      end
    end

    def previous_step
      :kind_of_nursery
    end

    def search_term_entered_in_no_js_fallback_form?
      # This combination of fields is only used in the no-js fallback form
      # institution_name will be set from the search term being entered into the search
      # field that is only visible when JS is disabled.
      wizard.store["institution_name"].present?
    end

    def possible_institutions
      @possible_institutions ||= Institution
        .where(institutionable_type: %w[School LocalAuthority])
        .open_school_or_non_school
        .search_by_name(institution_name)
        .limit(10)
    end

  private

    def selected_institution
      return nil if institution_id.blank? || institution_id == "other"

      @selected_institution ||= Institution.find(institution_id)
    end

    def institution_location
      wizard.store["institution_location"]
    end

    def validate_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?
        errors.add(:institution_name, :no_results, name: institution_name)
      end
    end
  end
end
