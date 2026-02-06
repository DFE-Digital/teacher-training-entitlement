module Questionnaires
  class ChooseATteAndProvider < Base
    def previous_step
      :choose_your_provider
    end

    def next_step; end
  end
end
