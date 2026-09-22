module Helpers
  module BulkOperations
    def applications_file
      @applications_file ||= tempfile_with_bom(Application.all.pluck(:ecf_id).join("\n"))
    end

    def empty_file
      @empty_file ||= Tempfile.new
    end

    def wrong_format_file
      @wrong_format_file ||= tempfile_with_bom("one,two\nthree,four\n")
    end

    def declarations_file
      @declarations_file ||= begin
        lead_provider = create(:lead_provider)
        delivery_partner = create(:delivery_partner)
        course_cohort_provider = create(:course_cohort_provider, lead_provider:)
        course_cohort = course_cohort_provider.course_cohort
        course = course_cohort.course

        # Create required partnerships
        create(:delivery_partnership, course_cohort:, delivery_partner:, lead_provider:)

        participant1 = create(:user)
        participant2 = create(:user)

        create(:application, :accepted, user: participant1, course_cohort:, lead_provider:)
        create(:application, :accepted, user: participant2, course_cohort:, lead_provider:)

        milestone = course.milestones.find_or_create_by!(declaration_type: Milestone::STARTED) do |record|
          record.acceptance_window_start_offset = 0
          record.acceptance_window_end_offset = 30
        end
        declaration_date = (milestone.acceptance_window_start_date_for(training_starts_at: course_cohort.training_starts_at) + 1.day).rfc3339

        tempfile_with_bom <<~CSV
          participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
          #{participant1.ecf_id},started,#{declaration_date},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
          #{participant2.ecf_id},completed,#{declaration_date},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",TRUE
        CSV
      end
    end
  end
end
