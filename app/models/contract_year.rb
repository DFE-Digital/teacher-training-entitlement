class ContractYear < ApplicationRecord
  has_paper_trail

  belongs_to :lead_provider
  belongs_to :course

  validates :lead_provider, presence: true
  validates :course, presence: true
  validates :lead_provider, uniqueness: { scope: %i[course_id academic_year] }

  validates :academic_year, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :recruitment_target, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :service_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :teacher_funding, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
