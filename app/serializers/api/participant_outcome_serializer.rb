module API
  class ParticipantOutcomeSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "outcome" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:state)
      field(:completion_date)
      field(:course_identifier) { |outcome| outcome.declaration.application.course.identifier }
      field(:participant_id) { |outcome| outcome.user.ecf_id }
      field(:created_at)
      field(:updated_at)

      view :v1 do
      end
    end

    %i[v1].each do |version|
      view version do
        association :attributes, blueprint: AttributesSerializer, view: version do |outcome|
          outcome
        end
      end
    end
  end
end
