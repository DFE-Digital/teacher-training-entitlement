module Registrations
  module Steps
    module Shared
      class HtmlPartial < Step
        def self.with_partial(partial)
          const_set(:PARTIAL_NAME, partial.to_s.freeze)
        end

        def partial_name
          self.class.const_get(:PARTIAL_NAME, false)
        end
      end
    end
  end
end
