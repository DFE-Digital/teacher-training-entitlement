module Admin
  class ApplicationHistoryComponent < BaseComponent
    attr_reader :record, :changes

    def initialize(record:, &)
      @record = record
      @changes = build_changes(&)
    end

  private

    def build_changes
      version_changes = build_version_changes
      event_changes = build_event_changes

      (version_changes + event_changes).sort_by { |change| change[:at] }.reverse
    end

    def build_version_changes
      record.versions.where(event: "update").where.not(object_changes: nil)
        .select { |version| (version.object_changes.keys - %w[updated_at]).any? }
        .pluck(:created_at, :whodunnit, :object_changes)
        .map { |created_at, whodunnit, object_changes|
        object_changes.except("updated_at", "funding_eligiblity_status_code", "status").map do |key, value|
          {
            title: show_object_changes(key, value),
            by: show_whodunnit(whodunnit),
            at: created_at,
            description: description(object_changes, key, value),
          }
        end
      }.flatten
    end

    def build_event_changes
      record.application_events.includes(:lead_provider).map do |event|
        {
          title: event_title(event),
          by: event_by(event),
          at: event.created_at,
          description: event_description(event),
        }
      end
    end

    def event_title(event)
      case event
      when StateChange
        "Status changed to #{event.status}"
      when Notification
        "Notification sent: #{event.event.humanize}"
      else
        event.event.humanize
      end
    end

    def event_by(event)
      event.lead_provider.present? ? event.lead_provider.name : "system"
    end

    def event_description(event)
      return if event.reason.blank?

      { inset: "Reason: #{event.reason}" }
    end

    def show_object_changes(key, change)
      if key =~ /_id$/
        label = key.sub(/_id$/, "")
        change_to = format_association_change(label, change[1])
      else
        label = key
        change_to = format_change(change[1])
      end

      record.class.human_attribute_name(label).tap do |output_string|
        if key == "notes"
          output_string << " updated"
        else
          output_string << " changed"
          output_string << " to #{change_to}" if change_to
        end
      end
    end

    def description(object_changes, key, value)
      case key
      when "notes"
        { details_summary: "Review notes", details: simple_format(value[1]) }
      when "eligible_for_funding"
        { bullet: "Status code changed to #{object_changes['funding_eligiblity_status_code'][1]}" }
      end
    end

    def format_association_change(label, change)
      return unless change

      fallback = "ID: #{change}"
      reflection = record.class.reflections[label]
      if reflection
        object = reflection.klass.find(change)
        object.respond_to?(:name) ? object.name : fallback
      else
        fallback
      end
    end

    def format_change(value)
      if [TrueClass, FalseClass].include?(value.class)
        value ? "yes" : "no"
      else
        value
      end
    end

    def show_whodunnit(whodunnit)
      if whodunnit.nil?
        "unknown"
      elsif whodunnit.match(/AdminUser\ (\d+)/)
        ::AdminUser.find(whodunnit.match(/AdminUser\ (\d+)/)[1]).full_name
      elsif whodunnit.match(/Public User\ (\d+)/)
        User.find(whodunnit.match(/Public User\ (\d+)/)[1]).full_name
      elsif whodunnit.match(/Lead provider\ (\d+)/)
        LeadProvider.find(whodunnit.match(/Lead provider\ (\d+)/)[1]).name
      else
        whodunnit
      end
    rescue ActiveRecord::RecordNotFound
      whodunnit
    end
  end
end
