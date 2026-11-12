# Copies the delegated record columns onto institutions and backfills institution_type
# and open, in batches. Idempotent: re-running overwrites with the delegated values.
class Institutions::BackfillFromDelegated
  BATCH_SIZE = 1_000

  SCHOOL_COLUMNS = %w[
    close_date
    establishment_status_code
    establishment_status_name
    establishment_type_code
    establishment_type_name
    eyl_funding_eligible
    high_pupil_premium
    la_code
    la_name
    last_changed_date
    number_of_pupils
    phase_name
    phase_type
    ukprn
  ].freeze

  def call
    Institution.in_batches(of: BATCH_SIZE) do |batch|
      ids = batch.pluck(:id)
      fold_schools(ids)
      fold_local_authorities(ids)
      fold_private_childcare_providers(ids)
    end
  end

private

  def fold_schools(ids)
    assignments = SCHOOL_COLUMNS.map { |column| "#{column} = schools.#{column}" }
    assignments << "open = (schools.establishment_status_code IN ('1', '3', '4'))"
    execute("School", "schools", ids, assignments)

    School.joins(:institution).where(institutions: { id: ids })
          .pluck("institutions.id", "institutions.name", "schools.establishment_type_code")
          .group_by { |_id, name, code| school_type(name, code) }
          .each { |slug, rows| Institution.where(id: rows.map(&:first)).update_all(institution_type: slug) }
  end

  def school_type(name, code)
    Institutions::ClassifyType.new(institutionable: School.new(establishment_type_code: code), name:).call
  end

  def fold_local_authorities(ids)
    execute("LocalAuthority", "local_authorities", ids, ["high_pupil_premium = local_authorities.high_pupil_premium", "open = TRUE"])
    Institution.where(id: ids, institutionable_type: "LocalAuthority").update_all(institution_type: Institution::LOCAL_AUTHORITY)
  end

  def fold_private_childcare_providers(ids)
    assignments = [
      "disabled_at = private_childcare_providers.disabled_at",
      "early_years_individual_registers = private_childcare_providers.early_years_individual_registers::jsonb",
      "local_authority_name = private_childcare_providers.local_authority",
      "provider_compulsory_childcare_register_flag = private_childcare_providers.provider_compulsory_childcare_register_flag",
      "provider_early_years_register_flag = private_childcare_providers.provider_early_years_register_flag",
      "open = (private_childcare_providers.disabled_at IS NULL)",
    ]
    execute("PrivateChildcareProvider", "private_childcare_providers", ids, assignments)
    Institution.where(id: ids, institutionable_type: "PrivateChildcareProvider")
               .update_all(institution_type: Institution::PRIVATE_CHILDCARE_PROVIDER)
  end

  def execute(type, table, ids, assignments)
    sql = <<~SQL.squish
      UPDATE institutions SET #{assignments.join(", ")}
      FROM #{table}
      WHERE institutions.institutionable_type = #{Institution.connection.quote(type)}
        AND institutions.institutionable_id = #{table}.id
        AND institutions.id IN (#{ids.map(&:to_i).join(",")})
    SQL
    Institution.connection.execute(sql)
  end
end
