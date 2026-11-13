module API
  module V2
    class OutcomeSerializer
      include JSONAPI::Serializer

      set_type :outcome
      set_id :ecf_id

      attribute :state
      attribute :completion_date
    end
  end
end
