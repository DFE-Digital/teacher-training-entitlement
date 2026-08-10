class AddAcademicYearToStatement < ActiveRecord::Migration[8.1]
  def change
    # track which academic year the course cohort belongs
    add_column :statements, :academic_year, :integer
  end
end
