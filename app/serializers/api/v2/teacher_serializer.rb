module API
  module V2
    class TeacherSerializer
      include JSONAPI::Serializer

      set_type :teacher
      set_id { |user| user.trn.presence || user.ecf_id }

      attribute :ecf_id
      attribute :trn
    end
  end
end
