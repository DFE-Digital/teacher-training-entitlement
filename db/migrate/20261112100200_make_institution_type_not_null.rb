class MakeInstitutionTypeNotNull < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_check_constraint :institutions, "institution_type IS NOT NULL", name: "institutions_institution_type_null", validate: false
    validate_check_constraint :institutions, name: "institutions_institution_type_null"
    change_column_null :institutions, :institution_type, false
    remove_check_constraint :institutions, name: "institutions_institution_type_null"
  end

  def down
    change_column_null :institutions, :institution_type, true
  end
end
