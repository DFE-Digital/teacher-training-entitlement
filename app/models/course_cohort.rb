class CourseCohort < ApplicationRecord
  belongs_to :course
  belongs_to :cohort
  belongs_to :schedule

  has_many :course_cohort_providers, dependent: :destroy
  has_many :lead_providers, through: :course_cohort_providers

  has_many :applications

  validates :ecf_id, uniqueness: { case_sensitive: false }

  delegate :name, to: :cohort
end
