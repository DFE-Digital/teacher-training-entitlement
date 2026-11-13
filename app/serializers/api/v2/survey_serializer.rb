module API
  module V2
    # Surveys have no backing data yet, so no survey resource is ever serialized.
    class SurveySerializer
      include JSONAPI::Serializer

      set_type :survey
    end
  end
end
