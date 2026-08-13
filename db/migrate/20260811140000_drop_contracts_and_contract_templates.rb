class DropContractsAndContractTemplates < ActiveRecord::Migration[8.1]
  def change
    drop_table :contracts do |t|
      t.bigint :contract_template_id, null: false
      t.bigint :course_id, null: false
      t.datetime :created_at, null: false
      t.bigint :statement_id, null: false
      t.datetime :updated_at, null: false
      t.index %w[contract_template_id], name: "index_contracts_on_contract_template_id"
      t.index %w[course_id], name: "index_contracts_on_course_id"
      t.index %w[statement_id course_id], name: "index_contracts_on_statement_id_and_course_id", unique: true
      t.index %w[statement_id], name: "index_contracts_on_statement_id"
    end

    drop_table :contract_templates do |t|
      t.datetime :created_at, null: false
      t.uuid :ecf_id
      t.decimal :monthly_service_fee, default: "0.0"
      t.integer :number_of_payment_periods
      t.integer :output_payment_percentage, default: 60, null: false
      t.decimal :per_participant, null: false
      t.integer :recruitment_target, null: false
      t.integer :service_fee_installments, null: false
      t.integer :service_fee_percentage, default: 40, null: false
      t.boolean :special_course, default: false, null: false
      t.decimal :targeted_delivery_funding_per_participant, default: "100.0"
      t.datetime :updated_at, null: false
      t.index %w[ecf_id], name: "index_contract_templates_on_ecf_id", unique: true
    end
  end
end
