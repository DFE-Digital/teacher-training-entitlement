class Institution < ApplicationRecord
  delegated_type :institutionable, types: %w[School PrivateChildcareProvider LocalAuthority], dependent: :destroy
end
