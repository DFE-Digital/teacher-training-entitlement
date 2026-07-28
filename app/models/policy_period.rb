class PolicyPeriod < ApplicationRecord
  has_many :course_cohorts
  has_many :contract_policy_periods, dependent: :destroy
  has_many :contracts, through: :contract_policy_periods

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
end
