class AddInstitutionSearchIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    search_columns = %w[name postcode postcode_without_spaces]
      .map { |col| "coalesce(#{col}, '')" }
      .join(" || ' ' || ")

    safety_assured do
      add_column :institutions, :search_vector, :tsvector,
                 as: "to_tsvector('english', #{search_columns})",
                 stored: true

      add_index :institutions, :search_vector, using: :gin, algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      remove_index :institutions, :search_vector, algorithm: :concurrently
      remove_column :institutions, :search_vector
    end
  end
end
