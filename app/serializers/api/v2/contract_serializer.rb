module API
  module V2
    # Contract resources are linkage-only for now: `include=contract` is rejected until
    # training-specific contract dates have an agreed representation (see api-v2/025).
    class ContractSerializer
      include JSONAPI::Serializer

      set_type :contract
    end
  end
end
