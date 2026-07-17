class AddParticipantFundingToCourseCohorts < ActiveRecord::Migration[8.1]
  def change
    add_column :course_cohorts, :participant_funding, :decimal, precision: 10, scale: 2
  end
end
