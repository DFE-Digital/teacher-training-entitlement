module Questionnaires
  class ChoosePrivateChildcareProvider < Base
    attr_accessor :institution_name, :institution_id

    validates :institution_id, numericality: { only_integer: true }, unless: -> { institution_id.blank? || institution_id == "other" }
    validates :institution_name, length: { maximum: 64 }

    validate :validate_institution_id_selected
    validate :validate_private_childcare_provider_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_id
      ]
    end

    def next_step
      if no_js_fallback_search_loop? || institution_id.blank?
        :choose_private_childcare_provider
      else
        :choose_your_npq
      end
    end

    def previous_step
      :have_ofsted_urn
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :institution_id,
          locale_name: :choose_private_childcare_provider,
          picker: :"private-childcare-provider",
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :institution_name,
            locale_name: :choose_private_childcare_provider_search,
          ),
        ),
      ]
    end

    def possible_institutions
      @possible_institutions ||= begin
        base = Institution.where(institutionable_type: "PrivateChildcareProvider")
        institution_name.present? ? base.search_by_name(institution_name).limit(10) : base.limit(10)
      end
    end

  private

    def selected_institution
      return nil if institution_id.blank? || institution_id == "other"

      @selected_institution ||= Institution.find(institution_id)
    end

    def search_term_entered_in_no_js_fallback_form?
      wizard.store["institution_name"].present?
    end

    def no_js_fallback_search_loop?
      institution_id == "other"
    end

    def validate_private_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?
        errors.add(:institution_name, :no_results, urn: institution_name)
      end
    end

    def validate_institution_id_selected
      return if no_js_fallback_search_loop?
      return if institution_id.blank?

      return if selected_institution.present?

      errors.add(:institution_id, :no_results)
    end
  end
end
