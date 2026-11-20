class CourseUpliftInstitution < ApplicationRecord
  has_paper_trail

  belongs_to :course
  belongs_to :institution

  validates :institution_id, uniqueness: { scope: :course_id }
end
