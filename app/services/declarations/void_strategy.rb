module Declarations
  class VoidStrategy
    def self.for(declaration:)
      if declaration.clawbackable?
        Clawback.new(declaration:)
      else
        Void.new(declaration:)
      end
    end
  end
end
