require "rails_helper"

RSpec.describe CohortsComponent, type: :component do
  include Rails.application.routes.url_helpers
  let(:cohort_2027_october) { create(:cohort, registration_starts_at: Date.new(2027, 10, 1)) }
  let(:cohort_2026_october) { create(:cohort, registration_starts_at: Date.new(2026, 10, 1)) }
  let(:cohort_2026_february) { create(:cohort, registration_starts_at: Date.new(2026, 2, 1)) }

  let(:course_cohort_2027_october) { create(:course_cohort, cohort: cohort_2027_october, academic_year: 2027) }
  let(:course_cohort_2026_october) { create(:course_cohort, cohort: cohort_2026_october, academic_year: 2026) }
  let(:course_cohort_2026_february) { create(:course_cohort, cohort: cohort_2026_february, academic_year: 2026) }

  let(:course_cohorts) do
    [
      course_cohort_2027_october,
      course_cohort_2026_october,
      course_cohort_2026_february,
    ]
  end

  let(:current_path) { cohort_admin_courses_path(cohort_2026_october) }

  subject do
    described_class.new(
      current_path,
      course_cohorts:,
      base_path: :admin_courses_path,
    )
  end

  describe "#render?" do
    it "is true when course_cohorts are present" do
      expect(subject.render?).to be true
    end

    context "when there are no course_cohorts" do
      let(:course_cohorts) { [] }

      it "is false" do
        expect(subject.render?).to be false
      end
    end
  end

  describe "rendering" do
    before { render_inline(subject) }

    it "renders an 'All' link as the first item", pending: "disabled all link" do
      selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item:first-child > a.x-govuk-sub-navigation__link"

      expect(rendered_content).to have_css(selector, text: "All")
    end

    it "groups cohorts under their academic year, most recent year first" do
      years_selector = "ul.x-govuk-sub-navigation__section:not(.x-govuk-sub-navigation__section--nested) > li.x-govuk-sub-navigation__section-item > a.x-govuk-sub-navigation__link"

      years = page.all(years_selector).map(&:text)

      expect(years).to eq(["2027 / 2028", "2026 / 2027"])
    end

    it "nests each cohort under its academic year" do
      selector = %w[
        li.x-govuk-sub-navigation__section-item
        ul.x-govuk-sub-navigation__section--nested
        li.x-govuk-sub-navigation__section-item
        a.x-govuk-sub-navigation__link
      ].join(" > ")

      expect(rendered_content).to have_css(selector, text: "October 2027")
      expect(rendered_content).to have_css(selector, text: "October 2026")
      expect(rendered_content).to have_css(selector, text: "February 2026")
    end

    it "sorts cohorts within a year by recency, most recent first" do
      nested_selector = %w[
        ul.x-govuk-sub-navigation__section--nested
        a.x-govuk-sub-navigation__link
      ].join(" ")

      cohort_names = page.all(nested_selector).map(&:text)

      expect(cohort_names).to eq(["October 2027", "October 2026", "February 2026"])
    end

    it "links each cohort node to its own resource path" do
      expect(page.find_link("October 2026")[:href]).to eq(cohort_admin_courses_path(cohort_2026_october))
      expect(page.find_link("February 2026")[:href]).to eq(cohort_admin_courses_path(cohort_2026_february))
    end

    it "links the year node to the academic-year-scoped route, filtering across every cohort in that year" do
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

        expect(rendered_content).to have_css(current_leaf_selector, text: "October 2026")
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

        expect(page.all(february_leaf_selector).map(&:text)).not_to include("February 2026")
      end

      it "does not mark the sibling year as current" do
        year_selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

        expect(page.all(year_selector).map(&:text)).not_to include("2027")
      end
    end
  end

  context "when the resource has no academic-year-scoped route" do
    let(:course_cohorts) { [course_cohort_2026_october, course_cohort_2026_february] }
    let(:current_path) { admin_cohort_course_path(cohort_2026_october, course) }
    let(:course) { create(:course) }

    subject do
      described_class.new(
        current_path,
        course_cohorts:,
        base_path: :admin_course_path,
        resource: course,
        cohort_path: ->(cohort) { admin_cohort_course_path(cohort, course) },
      )
    end

    it "falls back to the most recent child cohort's own link" do
      render_inline(subject)

      expect(page.find_link("2026 / 2027")[:href]).to eq(admin_cohort_course_path(cohort_2026_october, course))
    end
  end

  context "when an explicit academic_year_path is given" do
    let(:course_cohorts) { [course_cohort_2026_october] }

    subject do
      described_class.new(
        current_path,
        course_cohorts:,
        base_path: :admin_courses_path,
        academic_year_path: ->(academic_year) { "/custom/#{academic_year}" },
      )
    end

    it "uses the custom academic_year_path callable" do
      render_inline(subject)

      expect(page.find_link("2026 / 2027")[:href]).to eq("/custom/2026")
    end
  end

  context "when the controller silently defaults to the current academic year (no cohort_id/academic_year param, no redirect)" do
    let(:current_path) { admin_courses_path }

    subject do
      described_class.new(
        current_path,
        course_cohorts:,
        base_path: :admin_courses_path,
        current_academic_year: 2026,
      )
    end

    it "marks the matching year as current even though the path has no academic-year segment" do
      render_inline(subject)

      parent_link_selector = "li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

      expect(rendered_content).to have_css(parent_link_selector, text: "2026 / 2027")
    end

    it "does not put aria-current on the defaulted year link" do
      render_inline(subject)

      expect(rendered_content).not_to have_css('a.x-govuk-sub-navigation__link[aria-current="true"]', exact_text: "2026 / 2027")
    end

    it "does not mark any leaf as current" do
      render_inline(subject)

      expect(rendered_content).not_to have_css("li.x-govuk-sub-navigation__section-item--current a[aria-current='true']")
    end

    it "does not mark a non-matching year as current" do
      render_inline(subject)

      year_selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

      expect(page.all(year_selector).map(&:text)).not_to include("2027 / 2028")
    end

    context "when the current_path is not the bare resource path (an explicit cohort/year was navigated to)" do
      let(:current_path) { cohort_admin_courses_path(cohort_2027_october) }

      it "does not additionally mark the defaulted academic year as current" do
        render_inline(subject)

        year_selector = "ul.x-govuk-sub-navigation__section > li.x-govuk-sub-navigation__section-item--current > a.x-govuk-sub-navigation__link"

        expect(page.all(year_selector).map(&:text)).not_to include("2026 / 2027")
      end
    end
  end

  context "when there are duplicate course_cohort rows for the same cohort" do
    let(:course_cohorts) do
      [
        course_cohort_2026_october,
        create(:course_cohort, cohort: cohort_2026_october, course: create(:course), academic_year: 2026),
      ]
    end

    it "dedupes leaf nodes by cohort" do
      render_inline(subject)

      selector = %w[
        ul.x-govuk-sub-navigation__section--nested
        li.x-govuk-sub-navigation__section-item
      ].join(" ")

      expect(rendered_content).to have_css(selector, count: 1)
    end
  end
end
