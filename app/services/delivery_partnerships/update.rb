module DeliveryPartnerships
  # Adds (or unarchives) and archives delivery partnerships for a course +
  # lead provider so the active ones match the selection. Runs in a single
  # transaction and keeps at least one active partnership.
  class Update
    Result = Struct.new(:success, :added, :removed, :error, keyword_init: true) do
      def success? = success
    end

    NONE_SELECTED_ERROR = "Select at least one delivery partner".freeze

    def initialize(course:, lead_provider:, selected_ids:)
      @course = course
      @lead_provider = lead_provider
      @selected_ids = selected_ids
    end

    def call
      ActiveRecord::Base.transaction do
        partnerships = DeliveryPartnership.where(course: @course, lead_provider: @lead_provider).lock.index_by(&:delivery_partner_id)
        changes = PendingChanges.new(course: @course, lead_provider: @lead_provider, selected_ids: @selected_ids).call

        return failure(NONE_SELECTED_ERROR) if changes.selected_ids.empty?

        changes.added.each { add(_1, partnerships[_1.id]) }
        changes.removed.each { partnerships.fetch(_1.id).archive! }

        Result.new(success: true, added: changes.added, removed: changes.removed)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      failure("The delivery partners could not be saved, please try again")
    end

  private

    def add(delivery_partner, partnership)
      if partnership
        partnership.unarchive!
      else
        DeliveryPartnership.create!(delivery_partner:, course: @course, lead_provider: @lead_provider)
      end
    end

    def failure(message)
      Result.new(success: false, added: [], removed: [], error: message)
    end
  end
end
