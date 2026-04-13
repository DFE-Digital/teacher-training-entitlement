module API
  class ParticipantSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "participant" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      view :v1 do
        field(:full_name)
        field(:teacher_reference_number) do |object, _options|
          object.trn if object.trn_verified
        end
        field(:updated_at) do |object, _options|
          updated_at(object)
        end

        field(:enrolments) do |object, options|
          applications(object, options).map do |application|
            {
              email: object.email,
              course_identifier: application.course.identifier,
              schedule_identifier: application&.schedule&.identifier,
              cohort: application.cohort&.start_year&.to_s,
              application_id: application.ecf_id,
              eligible_for_funding: application.eligible_for_funding,
              status: application.status,
              school_urn: application.school&.urn,
              withdrawal: withdrawal(application:, lead_provider: options[:lead_provider]),
              deferral: deferral(application:, lead_provider: options[:lead_provider]),
              created_at: application.accepted_at.rfc3339,
              funded_place: application.funded_place,
            }
          end
        end

        field(:participant_id_changes) do |object, _options|
          (object.participant_id_changes || []).map do |participant_id_change|
            API::ParticipantIdChangeSerializer.render_as_hash(participant_id_change)
          end
        end
      end

      class << self
        def applications(object, options)
          return Application.none unless options[:lead_provider]

          object.applications.select { |application| application.has_been_accepted? && application.lead_provider_id == options[:lead_provider].id }
        end

        def withdrawal(application:, lead_provider:)
          if application.withdrawn_status?
            # We are doing this in memory to avoid running those as queries on each request
            latest_event = application
              .application_events.sort_by(&:created_at)
              .reverse!
              .find { |e| e.status == Application::WITHDRAWN && e.lead_provider_id == lead_provider.id }

            if latest_event.present?
              {
                reason: latest_event.reason,
                date: latest_event.created_at.rfc3339,
              }
            end
          end
        end

        def deferral(application:, lead_provider:)
          if application.deferred_status?
            # We are doing this in memory to avoid running those as queries on each request
            latest_event = application
              .application_events.sort_by(&:created_at)
              .reverse!
              .find { |e| e.status == Application::DEFERRED && e.lead_provider_id == lead_provider.id }

            if latest_event.present?
              {
                reason: latest_event.reason,
                date: latest_event.created_at.rfc3339,
              }
            end
          end
        end

        def updated_at(user)
          (
            (user.participant_id_changes || []).map(&:updated_at) +
            (user.applications || []).map(&:updated_at) +
            [user.significantly_updated_at]
          ).compact.max
        end
      end
    end

    association :attributes, blueprint: AttributesSerializer do |participant|
      participant
    end

    %i[v1].each do |version|
      view version do
        association :attributes, blueprint: AttributesSerializer, view: version do |participant|
          participant
        end
      end
    end
  end
end
