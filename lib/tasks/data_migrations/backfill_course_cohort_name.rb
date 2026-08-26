namespace :data_migrations do
  desc "Backfill course cohort details"
  task backfill_cours: :environment do
    updated_count = 0
    skipped_count = 0

    CourseCohort.find_each do |cc|
      term_identifier = CourseCohort.school_term(cc.started_milestone&.acceptance_window_start_date)
      academic_year = cc.cohort.start_year
      cc.update!(term_identifier:, academic_year:)
      updated_count += 1
    end

    Rails.logger.debug "Updated #{updated_count} course cohort"
    Rails.logger.debug "Skipped #{skipped_count} course cohort"
  end
end
