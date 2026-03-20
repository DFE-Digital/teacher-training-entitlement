class RemoveColumnsFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_reference :applications, :itt_provider

      remove_column :applications, :headteacher_status, :string
      remove_column :applications, :employer_name, :string
      remove_column :applications, :employment_role, :string
      remove_column :applications, :employment_type, :string
      remove_column :applications, :tsf_primary_eligibility, :boolean
      remove_column :applications, :tsf_primary_plus_eligibility, :boolean
      remove_column :applications, :lead_mentor, :boolean
      remove_column :applications, :senco_start_date, :date
      remove_column :applications, :senco_in_role, :string
      remove_column :applications, :targeted_delivery_funding_eligibility, :boolean
      remove_column :applications, :teacher_catchment_synced_to_ecf, :boolean
      remove_column :applications, :DEPRECATED_cohort, :integer
      remove_column :applications, :DEPRECATED_itt_provider, :string

      drop_enum :headteacher_statuses, %w[no
                                          yes_when_course_starts
                                          yes_in_first_two_years
                                          yes_over_two_years
                                          yes_in_first_five_years
                                          yes_over_five_years]
      drop_enum :employment_types, %w[hospital_school
                                      lead_mentor_for_accredited_itt_provider
                                      local_authority_supply_teacher
                                      local_authority_virtual_school
                                      young_offender_institution
                                      other]
    end
  end
end
