class CourseCohortProvider < ApplicationRecord
  belongs_to :course_cohort
  belongs_to :lead_provider

  validates :course_cohort_id, uniqueness: { scope: :lead_provider_id }
  validates :allocation, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
