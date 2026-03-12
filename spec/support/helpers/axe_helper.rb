# frozen_string_literal: true

module AxeHelper
  extend RSpec::Matchers::DSL

  define :be_accessible do
    match do |page|
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa, :wcag22aa)
    end
  end
end
