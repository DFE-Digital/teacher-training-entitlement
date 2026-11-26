module API
  module V2
    class ExpectedDeclarationSerializer
      include JSONAPI::Serializer

      set_type :"expected-declaration"
      set_id :id

      attribute :declaration_type
    end
  end
end
