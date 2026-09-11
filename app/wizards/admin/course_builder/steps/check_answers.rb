module Admin
  module CourseBuilder
    module Steps
      class CheckAnswers
        include DfE::Wizard::Step

        def self.permitted_params
          []
        end
      end
    end
  end
end
