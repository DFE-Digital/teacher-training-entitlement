class InstitutionSerializer < Blueprinter::Base
  field(:id) { |i, _| i.institution.id }
  field(:name)
  field(:address) { |i, _| i.address_string }
end
