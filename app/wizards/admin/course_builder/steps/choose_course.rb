module Admin
  module CourseBuilder
    module Steps
      class ChooseCourse
        include DfE::Wizard::Step

        attribute :course_id, :integer

        validates :course_id, presence: true

        def self.permitted_params
          %i[course_id]
        end
      end
    end
  end
end
