module Registration
  module Steps
    module StateFundedSchool
      class PossibleFunding
        include Base

        FUNDING_AMOUNT = 200

        attribute :funding_amount, :integer

        # Incomplete until the teacher continues from the page, so that the
        # amount is stored and any earlier funding choice is dropped.
        validates :funding_amount, presence: true

        def self.permitted_params
          %i[funding_amount]
        end

        # A funded teacher has no funding choice: drop one given before going back.
        # The amount is not taken from the submitted params.
        def serializable_data
          super.merge("funding_amount" => FUNDING_AMOUNT, "funding" => nil)
        end
      end
    end
  end
end
