# frozen_string_literal: true

module AxeHelper
  extend RSpec::Matchers::DSL

  define :be_accessible do
    retries = 0

    match do |page|
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :wcag22aa)
    rescue UncaughtThrowError
      retry if (retries += 1) < 2
      raise
    end
  end
end
