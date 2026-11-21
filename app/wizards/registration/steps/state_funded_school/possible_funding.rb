module Registration
  module Steps
    module StateFundedSchool
      class PossibleFunding
        include Base

        attribute :funding_amount, :integer, default: 200

        def self.permitted_params
          []
        end

        # A funded teacher has no funding choice: drop one given before going back.
        def serializable_data
          super.merge("funding" => nil)
        end
      end
    end
  end
end
