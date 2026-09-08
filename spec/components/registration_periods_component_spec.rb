require "rails_helper"

RSpec.describe RegistrationPeriodsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let!(:reg_period_1) do
    create(
      :cohort,
      start_year: 2026,
      registration_starts_at: Date.new(2026, 7, 1),
      description: "NPD July 2026",
    )
  end
  let!(:reg_period_2) do
    create(
      :cohort,
      start_year: 2026,
      registration_starts_at: Date.new(2027, 2, 1),
      description: "NPD February 2026",
    )
  end
  let!(:reg_period_3) do
    create(
      :cohort,
      start_year: 2027,
      registration_starts_at: Date.new(2027, 7, 1),
      description: "NPD July 2027",
    )
  end
  let!(:reg_period_4) do
    create(
      :cohort,
      start_year: 2027,
      registration_starts_at: Date.new(2027, 10, 1),
      description: "NPQA October 2027",
    )
  end
  let!(:reg_period_5) do
    create(
      :cohort,
      start_year: 2027,
      registration_starts_at: Date.new(2028, 1, 1),
      description: "NPD January 2027",
    )
  end

  let(:current_path) { cohort_admin_courses_path(reg_period_1) }

  subject do
    described_class.new(
      current_path,
      base_path: :admin_courses_path,
    )
  end

  describe "rendering" do
    before { render_inline(subject) }

    it "groups registration periods under their academic year, most recent year first" do
      years_selector = "ul.x-govuk-sub-navigation__section:not(.x-govuk-sub-navigation__section--nested) > li.x-govuk-sub-navigation__section-item > a.x-govuk-sub-navigation__link"

      years = page.all(years_selector).map(&:text)

      expect(years).to include("2027 / 2028", "2026 / 2027")
    end

    it "nests each registration period under its academic year" do
      selector = %w[
        li.x-govuk-sub-navigation__section-item
        ul.x-govuk-sub-navigation__section--nested
        li.x-govuk-sub-navigation__section-item
        a.x-govuk-sub-navigation__link
      ].join(" > ")

      expect(rendered_content).to have_css(selector, text: "NPD January 2027")
      expect(rendered_content).to have_css(selector, text: "NPQA October 2027")
      expect(rendered_content).to have_css(selector, text: "NPD July 2027")
    end

    it "sorts registration periods within a year by recency, most recent first" do
      nested_selector = %w[
        ul.x-govuk-sub-navigation__section--nested
        a.x-govuk-sub-navigation__link
      ].join(" ")

      descriptions = page.all(nested_selector).map(&:text)
      expected_descriptions = [reg_period_5, reg_period_4, reg_period_3, reg_period_2, reg_period_1].map(&:description)
      expect(descriptions).to include(*expected_descriptions)
    end

    it "links each cohort node to its own resource path" do
      expect(page.find_link("NPD July 2026")[:href]).to eq(cohort_admin_courses_path(reg_period_1))
      expect(page.find_link("NPD February 2026")[:href]).to eq(cohort_admin_courses_path(reg_period_2))
    end

    it "links to the academic-year-scoped route" do
      expect(page.find_link("2026 / 2027")[:href]).to eq(academic_year_admin_courses_path(2026))
      expect(page.find_link("2027 / 2028")[:href]).to eq(academic_year_admin_courses_path(2027))
    end

    describe "current-state highlighting" do
      it "marks the current leaf as current, with aria-current, but not its parent link" do
        current_leaf_selector = %w[
          li.x-govuk-sub-navigation__section-item--current
          ul.x-govuk-sub-navigation__section--nested
          li.x-govuk-sub-navigation__section-item--current
          a.x-govuk-sub-navigation__link[aria-current="true"]
        ].join(" > ")

        expect(rendered_content).to have_css(current_leaf_selector, text: "NPD July 2026")
      end

      it "marks the parent year node as current when it contains the current leaf" do
        parent_link_selector = "li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

        expect(rendered_content).to have_css(parent_link_selector, text: "2026")
      end

      it "does not put aria-current on the parent year link" do
        expect(rendered_content).not_to have_css('a.x-govuk-sub-navigation__link[aria-current="true"]', exact_text: "2026")
      end

      it "does not mark the sibling leaf as current" do
        february_leaf_selector = %w[
          ul.x-govuk-sub-navigation__section--nested
          li.x-govuk-sub-navigation__section-item--current
        ].join(" ")

        expect(page.all(february_leaf_selector).map(&:text)).not_to include("NPD February 2026")
      end

      it "does not mark the sibling academic year as current" do
        year_selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

        expect(page.all(year_selector).map(&:text)).not_to include("2027")
      end
    end
  end

  context "when the controller silently defaults to the current academic year (no cohort_id/academic_year param, no redirect)" do
    let(:current_path) { admin_courses_path }

    subject do
      described_class.new(
        current_path,
        base_path: :admin_courses_path,
        current_academic_year: 2027,
      )
    end

    it "marks the matching year as current even though the path has no academic-year segment" do
      render_inline(subject)

      parent_link_selector = "li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

      expect(rendered_content).to have_css(parent_link_selector, text: "2027 / 2028")
    end

    it "does not put aria-current on the defaulted year link" do
      render_inline(subject)

      expect(rendered_content).not_to have_css('a.x-govuk-sub-navigation__link[aria-current="true"]', exact_text: "2027 / 2028")
    end

    it "does not mark any leaf as current" do
      render_inline(subject)

      expect(rendered_content).not_to have_css("li.x-govuk-sub-navigation__section-item--current a[aria-current='true']")
    end

    it "does not mark a non-matching year as current" do
      render_inline(subject)

      year_selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

      expect(page.all(year_selector).map(&:text)).not_to include("2026 / 2027")
    end

    context "when the current_path is not the bare resource path (an explicit cohort/year was navigated to)" do
      let(:current_path) { cohort_admin_courses_path(reg_period_3) }

      it "does not additionally mark the defaulted academic year as current" do
        render_inline(subject)

        year_selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

        expect(page.all(year_selector).map(&:text)).not_to include("2026 / 2027")
      end
    end
  end
end
