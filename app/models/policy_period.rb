class PolicyPeriod < ApplicationRecord
  has_many :course_cohorts

  validates :start_date, presence: true
  validates :end_date, presence: true
end
