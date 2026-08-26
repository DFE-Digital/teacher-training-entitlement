class RegistrationJourney < ApplicationRecord
  self.ignored_columns += %w[funding_type]

  belongs_to :course, optional: true
  has_many :registration_steps, -> { ordered }, dependent: :destroy

  before_save :set_slug

private

  def set_slug
    return if slug.present? || !name_changed?

    self.slug = name.underscore.parameterize.underscore.gsub("_", "-")
  end
end
