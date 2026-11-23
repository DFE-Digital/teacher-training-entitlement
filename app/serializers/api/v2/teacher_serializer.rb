module API
  module V2
    class TeacherSerializer
      include JSONAPI::Serializer

      set_type :teacher
      set_id { |user| identifier(user) }

      attribute :ecf_id
      attribute :trn

      # Teachers are identified by TRN (leading zeroes kept) when known, else by ecf_id.
      def self.identifier(user)
        user.trn.presence || user.ecf_id
      end
    end
  end
end
