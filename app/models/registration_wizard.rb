require "active_support/time"

class RegistrationWizard
  include ActiveModel::Model
  include ActionView::Helpers::TranslationHelper

  class InvalidStep < StandardError; end
  class RemovedStep < StandardError; end

  Answer = Struct.new(:key, :value, :change_step)

  VALID_REGISTRATION_STEPS = %i[
    auth_callback
    start
    closed
    course_start_date
    cannot_register_yet
    choose_your_course
    choose_your_provider
    choose_a_tte_and_provider
    teacher_catchment
    work_setting
    choose_school
    kind_of_nursery
    possible_funding
    ineligible_for_funding
    funding_your_course
    share_provider
    check_answers
    have_ofsted_urn
  ].freeze

  REMOVED_REGISTRATION_STEPS = %i[].freeze

  attr_reader :current_step, :params, :store, :request, :current_user

  delegate :before_render,
           :after_render,
           :skip_step?,
           to: :form

  delegate :session, to: :request

  class << self
    def validate_step!(step)
      return step.to_sym if VALID_REGISTRATION_STEPS.include?(step.to_sym)

      raise RemovedStep, "This step has been removed: #{step}" if REMOVED_REGISTRATION_STEPS.include?(step.to_sym)

      raise InvalidStep, "Could not find step: #{step}"
    end

    def fetch_step(step)
      validate_step!(step)

      "Questionnaires::#{step.to_s.camelcase}".constantize
    end

    def permitted_params_for_step(step)
      fetch_step(step).permitted_params
    end
  end

  def initialize(current_step:, store:, request:, current_user:, params: {})
    set_current_step(current_step)

    @current_user = current_user
    @params = params
    @store = store
    @request = request

    load_current_user_into_store
  end

  def form
    @form ||= begin
      hash = store.slice(*form_class.permitted_params.map(&:to_s))
      form_class.new hash.merge(params, wizard: self)
    end
  end

  def save!
    form.attributes.each { |k, v| store[k.to_s] = v }
    form.after_save
  end

  def next_step_path
    form.next_step.to_s.dasherize
  end

  def previous_step_path
    form.previous_step.to_s.dasherize
  end

  def answers
    array = []

    array << Answer.new("Course start", store["course_start"], :course_start_date)
    array << Answer.new("Course", I18n.t(course.identifier, scope: "course.name"), :choose_your_course)
    array << Answer.new("Provider", lead_provider&.name, :choose_your_provider)
    array << Answer.new("Workplace in England", teacher_catchment_humanized, :teacher_catchment)
    array << Answer.new("Work setting", t("work_setting"), :work_setting)
    if kind_of_nursery_public?
      array << Answer.new("Nursery", t("kind_of_nursery"), :kind_of_nursery)
    end
    array << Answer.new("Workplace", institution_from_store.try(:name_with_address), :choose_school)
    if store["funding"].present?
      array << Answer.new("Course funding", I18n.t(store["funding"], scope: "helpers.label.registration_wizard.funding_options"), :funding_your_course)
    end

    array
  end

  def query_store
    @query_store ||= RegistrationQueryStore.new(store:)
  end

private

  delegate :course,
           :formatted_date_of_birth,
           :has_ofsted_urn?,
           :inside_catchment?,
           :kind_of_nursery_private?,
           :kind_of_nursery_public?,
           :lead_provider,
           :teacher_catchment_humanized,
           :trn_set_via_fallback_verification_question?,
           :works_in_another_setting?,
           :works_in_childcare?,
           :works_in_other?,
           :works_in_school?,
           :work_setting,
           :young_offender_institution?,
           to: :query_store

  def form_for_step(step)
    form_class = self.class.fetch_step(step)
    hash = store.slice(*form_class.permitted_params.map(&:to_s))
    form_class.new hash.merge(wizard: self)
  end

  def load_current_user_into_store
    store["current_user_id"] = current_user&.id
  end

  def institution_from_store
    return nil if store["institution_id"].blank?

    @institution_from_store ||= Institution.find(store["institution_id"])
  end

  def funding_eligibility_calculator
    FundingEligibility.new(
      course:,
      institution: institution_from_store,
      inside_catchment: inside_catchment?,
      query_store:,
    )
  end

  def form_class
    @form_class ||= self.class.fetch_step(current_step)
  end

  def set_current_step(step)
    @current_step = self.class.validate_step!(step)
  end

  def t(key)
    I18n.t(store[key], scope: "helpers.label.registration_wizard.#{key}_options")
  end
end
