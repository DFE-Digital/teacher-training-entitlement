class ReplaceFundingEligibilityColumns < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      rename_column :applications, :funding_eligiblity_status_code, :funding_eligibility

      execute <<~SQL
        UPDATE applications
        SET funding_eligibility = CASE
          WHEN eligible_for_funding THEN 'funded'
          WHEN funding_eligibility IS NULL OR funding_eligibility IN ('', 'funded', 'marked_funded_by_policy') THEN 'ineligible_setting'
          ELSE funding_eligibility
        END
      SQL

      remove_column :applications, :eligible_for_funding
    end
  end

  def down
    safety_assured do
      add_column :applications, :eligible_for_funding, :boolean, default: false, null: false

      execute <<~SQL
        UPDATE applications SET eligible_for_funding = (funding_eligibility = 'funded')
      SQL

      rename_column :applications, :funding_eligibility, :funding_eligiblity_status_code
    end
  end
end
