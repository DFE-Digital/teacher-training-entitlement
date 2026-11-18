class PrivateChildcareProviderSerializer < Blueprinter::Base
  exclude(:id)
  field(:identifier) { |pcp, _| "PrivateChildcareProvider-#{pcp.urn}" }
  field(:urn)
  field(:name)
  field(:address) { |pcp, _| pcp.address_string }
end
