class AddTermIdentifierToCourseCohort < ActiveRecord::Migration[8.1]
  def change
    create_enum :term_identifiers, %w[autumn spring summer]

    add_column :course_cohorts, :term_identifier, :enum, enum_type: "term_identifiers", default: nil
    transaction do
      CourseCohort.find_each do |cc|
        start_date = cc.started_milestone&.acceptance_window_start_date
        cc.update!(term_identifier: CourseCohort.school_term(start_date))
      end
    end
  end
end
