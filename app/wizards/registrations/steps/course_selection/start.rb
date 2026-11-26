module Registrations
  module Steps
    module CourseSelection
      class Start
        include DfE::Wizard::Step

        TITLE = "Start".freeze
        PARTIAL = "html_partial".freeze
        PARTIAL_NAME = "registrations/course_selection/start".freeze
        attribute :self_funded, :string

        def self.permitted_params = %i[self_funded]
      end
    end
  end
end
