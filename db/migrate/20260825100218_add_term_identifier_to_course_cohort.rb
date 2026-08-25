class AddTermIdentifierToCourseCohort < ActiveRecord::Migration[8.1]
  def change
    create_enum :term_identifiers, %w[autumn spring summer]

    add_column :course_cohorts, :term_identifier, :enum, enum_type: "term_identifiers", default: nil
  end
end
