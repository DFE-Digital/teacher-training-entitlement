module Registration
  module Steps
    class CannotRegisterYet
      include Base

      def self.permitted_params
        []
      end
    end
  end
end
