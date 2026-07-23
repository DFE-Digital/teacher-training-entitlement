module Declarations
  class VoidStrategy
    def self.for(declaration:)
      if declaration.paid_state?
        Clawback.new(declaration:)
      else
        Void.new(declaration:)
      end
    end
  end
end
