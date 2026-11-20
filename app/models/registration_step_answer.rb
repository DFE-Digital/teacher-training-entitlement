class RegistrationStepAnswer < ApplicationRecord
  include RegistrationStepRedirectable

  belongs_to :registration_step

  validate :state_store_key_matches_siblings

  # Most answers only collect a value and continue along the step's configured
  # default route.
  # However answers can be configured to take the user to different paths/branches
  # depending on the chosen answer.
  # Setting +next_step+ when selecting this particular answer should
  # override that route and take the user to a different step.
  belongs_to :next_step, class_name: "RegistrationStep", optional: true

  scope :ordered, -> { order(:position, :id) }

  def answer_matches?(answer_value:)
    value.to_s == answer_value.to_s
  end

  def has_state_store_answer_key?
    state_store_key.present?
  end

private

  #
  # A step's answer routes must all read from the same state-store value.
  # Usually a registration_step_answer uses the parent registration_step answer key
  # but sometimes we need to send a user to a different branch depending on
  # a value injected into the state store.
  # If we do configure this then all siblings must have the same state_store_key
  #
  def state_store_key_matches_siblings
    return unless registration_step

    sibling_answers = registration_step.registration_step_answers.to_a.reject do |answer|
      answer.equal?(self) || (id.present? && answer.id == id)
    end
    state_store_keys = [state_store_key, *sibling_answers.map(&:state_store_key)]
    return unless state_store_keys.any?(&:present?)

    return if state_store_keys.all?(&:present?) && state_store_keys.uniq.one?

    errors.add(:state_store_key, "must be present and match the state store key on sibling answers")
  end
end
