class CreateProviderCourseProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :provider_course_profiles do |t|
      t.references :course, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.string :url

      t.timestamps
    end

    add_index :provider_course_profiles,
              %i[course_id lead_provider_id],
              unique: true
  end
end
