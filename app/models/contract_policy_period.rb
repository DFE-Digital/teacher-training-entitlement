class ContractPolicyPeriod < ApplicationRecord
  belongs_to :contract
  belongs_to :policy_period
end
