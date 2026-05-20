module ReceptionRegistrations
  module Forms
    class NoOpForm
      include DfE::Wizard::Step

      def self.permitted_params
        []
      end
    end
  end
end
