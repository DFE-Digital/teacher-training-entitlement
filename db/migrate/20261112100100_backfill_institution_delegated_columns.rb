class BackfillInstitutionDelegatedColumns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    Institutions::BackfillFromDelegated.new.call
  end

  # Rollback is a no-op: reverting AddDelegatedColumnsToInstitutions drops the folded
  # columns, and institution_type / open are nullable again once the NOT NULL is reverted.
  def down; end
end
