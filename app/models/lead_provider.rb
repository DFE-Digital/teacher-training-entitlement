class LeadProvider < ApplicationRecord
  has_many :applications
  has_many :statements
  has_many :course_cohort_providers
  has_many :course_cohorts, through: :course_cohort_providers
  has_many :courses, through: :course_cohorts

  has_many :delivery_partnerships
  has_many :delivery_partners, through: :delivery_partnerships

  validates :name, presence: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :alphabetical, -> { order(name: :asc) }

  def self.for(course:, cohort: nil)
    course_cohorts = { course_id: course.id, cohort_id: cohort&.id || Cohort.current.id }
    LeadProvider.joins(course_cohort_providers: :course_cohort)
                .where(course_cohorts:)
  end

  def next_output_fee_statement(cohort)
    statements.next_output_fee_statements.where(cohort:).first
  end

  def delivery_partners_for_cohort(cohort)
    delivery_partners.where(delivery_partnerships: { cohort: })
  end

  def generate_token!
    scope = APIToken.scopes[:lead_provider]
    APIToken.create_with_random_token!(scope:, lead_provider: self)
  end
end
