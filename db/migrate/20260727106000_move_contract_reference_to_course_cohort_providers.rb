class MoveContractReferenceToCourseCohortProviders < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :course_cohort_providers, :contract, index: { algorithm: :concurrently } unless column_exists?(:course_cohort_providers, :contract_id)
    add_foreign_key :course_cohort_providers, :contracts, validate: false unless foreign_key_exists?(:course_cohort_providers, :contracts)

    reversible do |dir|
      dir.up do
        if table_exists?(:contract_course_cohorts)
          safety_assured do
            execute <<~SQL.squish
              UPDATE course_cohort_providers
              SET contract_id = matching_contracts.contract_id
              FROM (
                SELECT DISTINCT ON (contract_course_cohorts.course_cohort_id, contracts.lead_provider_id)
                  contract_course_cohorts.course_cohort_id,
                  contracts.lead_provider_id,
                  contracts.id AS contract_id
                FROM contract_course_cohorts
                INNER JOIN contracts ON contracts.id = contract_course_cohorts.contract_id
                ORDER BY contract_course_cohorts.course_cohort_id, contracts.lead_provider_id, contracts.id DESC
              ) matching_contracts
              WHERE course_cohort_providers.course_cohort_id = matching_contracts.course_cohort_id
              AND course_cohort_providers.lead_provider_id = matching_contracts.lead_provider_id
            SQL
          end
        end
      end
    end

    drop_table :contract_course_cohorts, if_exists: true do |t|
      t.references :contract, null: false, index: false
      t.references :course_cohort, null: false, index: false

      t.timestamps
    end
  end
end
