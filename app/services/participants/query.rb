module Participants
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, updated_since: :ignore, status: :ignore, from_participant_id: :ignore, sort: nil)
      @scope = all_participants
      @sort = sort

      where_lead_provider_is(lead_provider)
      where_updated_since(updated_since)
      where_status_in(status)
      where_from_participant_id_is(from_participant_id)
    end

    def participants
      scope.order(order_by)
    end

    def participant(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(Application.joins(:application_lead_providers).merge(ApplicationLeadProvider.current.where(lead_provider:)))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      users_updated_since = User.where(significantly_updated_at: updated_since..)
      applications_updated_since = User.where(id: Application.where(updated_at: updated_since..).select(:user_id))
      participant_id_changes_updated_since = User.where(id: ParticipantIdChange.where(updated_at: updated_since..).select(:user_id))
      scope.merge!(users_updated_since.or(applications_updated_since).or(participant_id_changes_updated_since))
    end

    def where_status_in(status)
      return if ignore?(filter: status)

      scope.merge!(User.includes(:applications).where(applications: { status: extract_conditions(status, allowlist: Application::STATUSES) }))
    end

    def where_from_participant_id_is(from_participant_id)
      return if ignore?(filter: from_participant_id)

      scope.merge!(scope.joins(:participant_id_changes).merge(ParticipantIdChange.where(from_participant_id:)))
    end

    def order_by
      sort_order(sort:, model: User, default: { created_at: :asc })
    end

    def all_participants
      User
        .distinct
        .joins(:applications).merge(Application.has_been_accepted)
        .includes(
          :participant_id_changes,
          applications: %i[
            course
            institution
            cohort
            lead_provider
            application_events
            application_lead_providers
            schedule
          ],
        )
    end
  end
end
