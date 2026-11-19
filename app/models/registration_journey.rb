class RegistrationJourney < ApplicationRecord
  belongs_to :course, optional: true
  has_many :registration_steps, -> { includes(%i[branch_join_step previous_step branch_decision_steps]) }, dependent: :destroy

  before_save :set_slug

  # The start step has no incoming default, answer-based, or branch-join route.
  # Requiring exactly one root keeps journey entry unambiguous without an order field.
  def start_step
    steps = registration_steps.to_a
    incoming_step_ids = steps.filter_map(&:branch_join_step_id) +
      steps.flat_map { |step| step.registration_step_answers.filter_map(&:next_step_id) }
    roots = steps.reject do |step|
      step.previous_step_id.present? || incoming_step_ids.include?(step.id)
    end

    return roots.first if roots.one?

    raise ArgumentError, "Registration journey #{slug} must have exactly one start step; found #{roots.size}"
  end

private

  # Creates a URL-friendly slug from the journey name when one is not supplied.
  def set_slug
    return if slug.present? || !name_changed?

    self.slug = name.underscore.parameterize.underscore.gsub("_", "-")
  end
end
