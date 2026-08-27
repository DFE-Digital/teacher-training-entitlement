module API
  class CourseCohortSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "schedule" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:course_identifier) { |cc| cc.course.identifier }
      field(:schedule_identifier)
      field(:academic_year, name: :cohort)
    end

    view :v1 do
      association :attributes, blueprint: AttributesSerializer do |cc|
        cc
      end
    end
  end
end
