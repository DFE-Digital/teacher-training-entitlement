class CohortProvider < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider

  validates :cohort_id, uniqueness: { scope: :lead_provider_id }
end
