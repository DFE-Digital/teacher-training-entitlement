class AddDelegatedColumnsToInstitutions < ActiveRecord::Migration[8.1]
  def change
    # from schools
    add_column :institutions, :close_date, :date
    add_column :institutions, :establishment_status_code, :text
    add_column :institutions, :establishment_status_name, :text
    add_column :institutions, :establishment_type_code, :text
    add_column :institutions, :establishment_type_name, :text
    add_column :institutions, :eyl_funding_eligible, :boolean, default: false
    add_column :institutions, :high_pupil_premium, :boolean, default: false, null: false
    add_column :institutions, :la_code, :text
    add_column :institutions, :la_name, :text
    add_column :institutions, :last_changed_date, :date
    add_column :institutions, :number_of_pupils, :integer
    add_column :institutions, :phase_name, :string
    add_column :institutions, :phase_type, :integer
    add_column :institutions, :ukprn, :text

    # from private_childcare_providers. local_authority is stored as local_authority_name
    # because delegated_type already defines Institution#local_authority.
    add_column :institutions, :disabled_at, :datetime
    add_column :institutions, :early_years_individual_registers, :jsonb, default: []
    add_column :institutions, :local_authority_name, :text
    add_column :institutions, :provider_compulsory_childcare_register_flag, :boolean
    add_column :institutions, :provider_early_years_register_flag, :boolean
  end
end
