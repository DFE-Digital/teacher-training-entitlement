class ProviderCourseProfile < ApplicationRecord
  belongs_to :course
  belongs_to :lead_provider

  validates :course_id, uniqueness: { scope: :lead_provider_id }
end
