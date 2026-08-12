class CourseCohortProvider < ApplicationRecord
  belongs_to :course_cohort
  belongs_to :lead_provider

  delegate :course, to: :course_cohort
  delegate :academic_year, to: :course_cohort, allow_nil: true

  validates :course_cohort_id, uniqueness: { scope: :lead_provider_id }
  validates :recruitment_target, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :teacher_funding, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def contract_year
    @contract_year ||=
      if academic_year.nil?
        ContractYear.find_by(lead_provider:, course:)
      else
        ContractYear.find_by(lead_provider:, course:, academic_year:)
      end
  end
end
