class AddContractualStores < ActiveRecord::Migration[8.1]
  def change
    # academic_year allow to set a contract for all year when nil
    # you can also have a default contract_year merge with a academic-year contract_year
    create_table :contract_years do |t|
      t.references :course, null: false, foreign_key: true, index: true
      t.references :lead_provider, null: false, foreign_key: true, index: true

      t.integer :academic_year
      t.integer :recruitment_target
      t.decimal :service_fee
      t.decimal :teacher_funding
      t.string :secondary_form_url
      t.string :course_url
      t.timestamps

      t.index %i[lead_provider_id course_id academic_year], unique: true
    end

    # course_cohort_providers is essentially a contract at the course_cohort level
    # TODO: rename later to `contract`
    # the combination of contract-year and course_cohort_provider aka contract
    # captures all the contractual data for a lead_provider / course
    add_column :course_cohort_providers, :teacher_funding, :decimal

    # lock in declaration computed contract.teacher_funding * milestone.percentage
    add_column :declarations, :value, :decimal

    safety_assured do
      remove_column :course_cohorts, :service_fee, :decimal
      remove_column :course_cohorts, :participant_funding, :decimal
    end
  end
end
