class InstitutionSerializer < Blueprinter::Base
  field(:id)
  field(:name)
  field(:address) { |institution, _| institution.address_string }
end
