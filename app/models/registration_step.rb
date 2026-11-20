class RegistrationStep < ApplicationRecord
  include RegistrationStepRedirectable

  belongs_to :registration_journey

  # previous_step links the normal step sequence and branch paths. Branch
  # decisions point to the shared re-entry step through branch_join_step:
  #
  #     [Choice] -> [A1] --┐
  #              -> [B1] --┴-> [Join]
  belongs_to :branch_join_step, class_name: "RegistrationStep", optional: true, inverse_of: :branch_decision_steps
  belongs_to :previous_step, class_name: "RegistrationStep", optional: true

  has_many :registration_step_answers, -> { includes(%i[next_step]).ordered }, dependent: :destroy

  # On a join step, returns the branch decisions that point back to it:
  #
  #     [Choice A] -> [...] --┐
  #     [Choice B] -> [...] --┴-> [This step]
  has_many :branch_decision_steps,
           ->(join_step) { where(registration_journey_id: join_step.registration_journey_id) },
           class_name: "RegistrationStep",
           foreign_key: :branch_join_step_id,
           inverse_of: :branch_join_step

  default_scope { includes(:registration_step_answers) }

  validate :branch_decision_answers_have_next_steps, if: -> { branch_join_step_id.present? }
  before_validation :set_requires_answer_for_required_types
  before_save :set_slug, :set_answer_display_name

  SERVICE_EXECUTE_POINT_OPTIONS = {
    before_show: "execute service before step",
    after_update: "execute service after step",
  }.freeze

  # Add a service to run before or after a step.
  # This allows you to inject state into the session during a registration journey.
  # For example, calculating the funding eligibility based on the
  #  answers a user has made during registration
  def add_service!(class_name:, execute_point:)
    service_config = config["services"] ||= []
    unless execute_point.to_sym.in?(SERVICE_EXECUTE_POINT_OPTIONS.keys)
      raise ArgumentError, "execute_point must be one of #{SERVICE_EXECUTE_POINT_OPTIONS.keys.join(', ')} - was given '#{execute_point}'"
    end

    service_config << { class_name:, execute_point: }
    update!(config:)
  end

  def set_answers!(answers:)
    RegistrationStepAnswer.transaction do
      registration_step_answers.destroy_all

      answers.each_with_index do |answer, position|
        attributes = answer_attributes(answer:, position:)
        registration_step_answers.create!(**attributes) if attributes
      end
    end
  end

  def text_data
    config.dig(type_as_param, "text") || []
  end

  def add_text!(text: nil, text_class: nil)
    config_for_type = config[type_as_param] ||= {}
    texts = config_for_type["text"] ||= []
    texts << { text: Array(text), text_class: }.compact

    update!(config:)
  end

  # Returns the branch root selected by +answer_value+, if that answer has an
  # explicit destination. The journey uses this to follow conditional edges.
  def next_registration_step_for(answers:)
    answer_value = answers[answer_key.to_sym]

    if registration_step_answers.any?(&:has_state_store_answer_key?)
      answer_value = answers[registration_step_answers.first.state_store_key.to_sym]
    end

    registration_step_answers.find { |rsa| rsa.answer_matches?(answer_value:) }&.next_step
  end

  # Returns this step's configured predecessor in the journey graph.
  def previous_registration_step
    registration_journey.registration_steps.find_by(id: previous_step_id)
  end

  # Resolves an answer-specific redirect first, then falls back to this step's
  # redirect configuration.
  def redirect_target_for(state_store:, answer: nil)
    answer_redirect = registration_step_answers.find { |configured_answer|
      configured_answer.redirect_path.present? && configured_answer.answer_matches?(answer_value: answer)
    }&.resolved_redirect_target(state_store:)

    answer_redirect || resolved_redirect_target(state_store:)
  end

  def display_answer_value(value:)
    matching_answer = registration_step_answers.find do |answer|
      answer.answer_matches?(answer_value: value)
    end

    matching_answer&.name || value
  end

  # Used by forms
  def type_as_param
    self.class.name.demodulize.underscore
  end

  def answer_key
    self[:state_store_key].presence || name_as_param
  end

  def name_as_param
    return nil unless name

    name.underscore.parameterize.underscore
  end

private

  # A step with a branch join must route every answer explicitly, so branch
  # traversal and answer clearing start from the same configured destinations.
  def branch_decision_answers_have_next_steps
    answers = registration_step_answers.to_a

    if answers.empty?
      errors.add(:registration_step_answers, "must be configured for a branch decision")
    elsif answers.any? { |answer| answer.next_step_id.blank? }
      errors.add(:registration_step_answers, "must each have a next step for a branch decision")
    end
  end

  def set_slug
    return if slug.present? || !name_changed?

    self.slug = name.underscore.parameterize.underscore.gsub("_", "-")
  end

  def set_answer_display_name
    self.answer_display_name = answer_key.to_s.humanize if answer_display_name.blank?
  end

  def set_requires_answer_for_required_types
    self.requires_answer = true if is_a?(RegistrationSteps::RadioButtons) || is_a?(RegistrationSteps::InstitutionChoice)
  end

  def answer_attributes(answer:, position:)
    answer = answer.to_h.deep_symbolize_keys
    return if answer[:name].blank?

    answer.slice(:name, :hint, :next_step_id, :redirect_path, :redirect_state_store_key, :state_store_key).compact_blank.merge(
      value: answer[:value],
      position:,
    )
  end
end
