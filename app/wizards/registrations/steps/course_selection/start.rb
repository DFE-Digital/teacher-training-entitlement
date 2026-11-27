module Registrations
  module Steps
    module CourseSelection
      class Start < Shared::HtmlPartial
        with_title "Start"
        with_partial "registrations/course_selection/start"
        attribute :self_funded, :string
        def self.permitted_params = %i[self_funded]
      end
    end
  end
end
