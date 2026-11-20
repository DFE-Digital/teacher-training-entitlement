module DeliveryPartnerships
  # Works out which delivery partners would be added to / removed from the
  # active partnerships of a course + lead provider for a given selection.
  # Does not write anything. Unknown delivery partner IDs are ignored.
  class PendingChanges
    Result = Struct.new(:selected_ids, :added, :removed, keyword_init: true) do
      def any? = added.any? || removed.any?
    end

    def initialize(course:, lead_provider:, selected_ids:)
      @course = course
      @lead_provider = lead_provider
      @selected_ids = Array(selected_ids).compact_blank.map(&:to_i).uniq
    end

    def call
      selected = DeliveryPartner.where(id: @selected_ids).index_by(&:id)
      active = active_partners.index_by(&:id)

      Result.new(
        selected_ids: selected.keys,
        added: selected.except(*active.keys).values.sort_by { _1.name.downcase },
        removed: active.except(*selected.keys).values.sort_by { _1.name.downcase },
      )
    end

  private

    def active_partners
      DeliveryPartner.where(id: DeliveryPartnership.active.where(course: @course, lead_provider: @lead_provider).select(:delivery_partner_id))
    end
  end
end
