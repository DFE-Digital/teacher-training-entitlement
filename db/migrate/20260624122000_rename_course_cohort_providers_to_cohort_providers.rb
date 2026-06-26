# frozen_string_literal: true

class RenameCourseCohortProvidersToCohortProviders < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      rename_table :course_cohort_providers, :cohort_providers if table_exists?(:course_cohort_providers)
    end

    add_reference :cohort_providers, :cohort, index: { algorithm: :concurrently } unless column_exists?(:cohort_providers, :cohort_id)

    safety_assured do
      execute <<~SQL.squish
        UPDATE cohort_providers
        SET cohort_id = course_cohorts.cohort_id
        FROM course_cohorts
        WHERE cohort_providers.course_cohort_id = course_cohorts.id
      SQL
    end

    add_index :cohort_providers,
              %i[cohort_id lead_provider_id],
              unique: true,
              algorithm: :concurrently,
              name: "index_cohort_providers_on_cohort_id_and_lead_provider_id",
              if_not_exists: true

    remove_index :cohort_providers, name: "idx_on_course_cohort_id_lead_provider_id_3527d5c43f", algorithm: :concurrently if index_exists?(:cohort_providers, %i[course_cohort_id lead_provider_id], name: "idx_on_course_cohort_id_lead_provider_id_3527d5c43f")
    remove_index :cohort_providers, name: "index_course_cohort_providers_on_course_cohort_id", algorithm: :concurrently if index_exists?(:cohort_providers, :course_cohort_id, name: "index_course_cohort_providers_on_course_cohort_id")

    safety_assured do
      remove_foreign_key :cohort_providers, :course_cohorts if foreign_key_exists?(:cohort_providers, :course_cohorts)
      remove_column :cohort_providers, :course_cohort_id if column_exists?(:cohort_providers, :course_cohort_id)
    end
  end

  def down
    add_reference :cohort_providers, :course_cohort, index: { algorithm: :concurrently } unless column_exists?(:cohort_providers, :course_cohort_id)

    safety_assured do
      execute <<~SQL.squish
        UPDATE cohort_providers
        SET course_cohort_id = course_cohorts.id
        FROM cohorts
        INNER JOIN course_cohorts
          ON course_cohorts.cohort_id = cohorts.id
          AND course_cohorts.course_id = cohorts.course_id
        WHERE cohort_providers.cohort_id = cohorts.id
      SQL
    end

    add_index :cohort_providers,
              %i[course_cohort_id lead_provider_id],
              unique: true,
              algorithm: :concurrently,
              name: "idx_on_course_cohort_id_lead_provider_id_3527d5c43f",
              if_not_exists: true

    remove_index :cohort_providers, name: "index_cohort_providers_on_cohort_id_and_lead_provider_id", algorithm: :concurrently if index_exists?(:cohort_providers, %i[cohort_id lead_provider_id], name: "index_cohort_providers_on_cohort_id_and_lead_provider_id")
    remove_index :cohort_providers, name: "index_cohort_providers_on_cohort_id", algorithm: :concurrently if index_exists?(:cohort_providers, :cohort_id, name: "index_cohort_providers_on_cohort_id")

    safety_assured do
      remove_column :cohort_providers, :cohort_id if column_exists?(:cohort_providers, :cohort_id)
      rename_table :cohort_providers, :course_cohort_providers if table_exists?(:cohort_providers)
    end
  end
end
