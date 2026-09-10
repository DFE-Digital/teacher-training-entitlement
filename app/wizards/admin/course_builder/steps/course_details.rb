module Admin
  module CourseBuilder
    module Steps
      class CourseDetails
        include DfE::Wizard::Step

        attribute :name, :string
        attribute :identifier, :string
        attribute :short_code, :string
        attribute :course_group, :string
        attribute :description, :string

        validates :name, presence: true

        def self.permitted_params
          %i[name identifier short_code course_group description]
        end
      end
    end
  end
end
