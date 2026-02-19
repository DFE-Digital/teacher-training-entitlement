class CourseCohortProvider < ApplicationRecord
  belongs_to :course_cohort
  belongs_to :lead_provider
end
