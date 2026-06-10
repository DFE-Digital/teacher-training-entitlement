class RemoveSuffixFromCohorts < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      remove_index :cohorts, :identifier
      remove_index :cohorts, %i[start_year suffix]
      remove_index :cohorts, :start_year

      remove_column :cohorts, :identifier
      remove_column :cohorts, :suffix

      add_column :cohorts, :identifier, :string
      execute <<~SQL.squish
        UPDATE cohorts
        SET identifier = #{identifier_expression}
      SQL
      change_column_null :cohorts, :identifier, false

      add_index :cohorts, :identifier, unique: true
      add_index :cohorts, :start_year
    end
  end

  def down
    safety_assured do
      remove_index :cohorts, :identifier
      remove_index :cohorts, :start_year

      remove_column :cohorts, :identifier

      add_column :cohorts, :suffix, :string, limit: 1
      execute <<~SQL.squish
        WITH ranked_cohorts AS (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY start_year ORDER BY registration_starts_at, id) AS suffix_index
          FROM cohorts
        )
        UPDATE cohorts
        SET suffix = CHR(96 + ranked_cohorts.suffix_index::integer)
        FROM ranked_cohorts
        WHERE cohorts.id = ranked_cohorts.id
      SQL
      change_column_default :cohorts, :suffix, "a"
      change_column_null :cohorts, :suffix, false
      add_column :cohorts, :identifier, :virtual, type: :varchar, as: "start_year || suffix", stored: true

      add_index :cohorts, :identifier, unique: true
      add_index :cohorts, %i[start_year suffix], unique: true
      add_index :cohorts, :start_year
    end
  end

private

  def identifier_expression
    <<~SQL.squish
      EXTRACT(YEAR FROM registration_starts_at)::integer::varchar || '-' ||
      CASE EXTRACT(MONTH FROM registration_starts_at)::integer
      WHEN 1 THEN 'January'
      WHEN 2 THEN 'February'
      WHEN 3 THEN 'March'
      WHEN 4 THEN 'April'
      WHEN 5 THEN 'May'
      WHEN 6 THEN 'June'
      WHEN 7 THEN 'July'
      WHEN 8 THEN 'August'
      WHEN 9 THEN 'September'
      WHEN 10 THEN 'October'
      WHEN 11 THEN 'November'
      WHEN 12 THEN 'December'
      END
    SQL
  end
end
