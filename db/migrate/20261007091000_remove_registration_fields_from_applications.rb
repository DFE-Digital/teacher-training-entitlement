class RemoveRegistrationFieldsFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :applications, :raw_application_data, :jsonb, default: {}
      remove_column :applications, :participant_outcome_state, :text
      remove_column :applications, :kind_of_nursery, :enum, enum_type: "kind_of_nurseries"
      remove_column :applications, :number_of_pupils, :integer, default: 0
      remove_column :applications, :ukprn, :text
      remove_column :applications, :on_submission_trn, :string
      remove_column :applications, :primary_establishment, :boolean, default: false
      remove_column :applications, :teacher_catchment_iso_country_code, :string, limit: 3
      remove_column :applications, :works_in_childcare, :boolean
      remove_column :applications, :works_in_nursery, :boolean
      remove_column :applications, :works_in_school, :boolean
      remove_column :applications, :review_status, :enum, enum_type: "review_statuses"
      remove_column :applications, :referred_by_return_to_teaching_adviser, :string
      remove_column :applications, :targeted_support_funding_eligibility, :boolean, default: false

      drop_enum :kind_of_nurseries,
                %w[
                  local_authority_maintained_nursery
                  preschool_class_as_part_of_school
                  private_nursery
                  another_early_years_setting
                  childminder
                ]
      drop_enum :review_statuses,
                %w[
                  needs_review
                  awaiting_information
                  reregister
                  decision_made
                ]
    end
  end
end
