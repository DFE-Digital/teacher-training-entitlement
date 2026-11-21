module Helpers
  module JourneyAssertionHelper
    # Pages that are not part of the course journey, in both journeys.
    SHARED_REGISTRATION_PAGES = %w[closed courses start].freeze

    # Paths are written for the legacy journey: `/registration/<step>`. With the dfe-wizard
    # journey on, a step lives under its course: `/registration/<course>/<step>`.
    def journey_path(path)
      return path unless Feature.registration_dfe_wizard?

      path.sub(%r{\A/registration/([\w-]+)\z}) do |match|
        next match if SHARED_REGISTRATION_PAGES.include?(Regexp.last_match(1))

        "/registration/#{CourseCohort.registerable.first.course.identifier}/#{Regexp.last_match(1)}"
      end
    end

    def navigate_to_page(path:, submit_form: false, submit_button_text: "Continue", &block)
      visit(journey_path(path))

      expect_page_to_have(path:, submit_form:, submit_button_text:, &block)
    end

    def expect_page_to_have(path:, submit_form: false, click_continue: false, submit_button_text: "Continue", &block)
      expect(page).to have_current_path(journey_path(path))

      @steps_visited ||= []
      @steps_visited << page.current_path unless page.current_path == "/"

      block.call if block_given?

      page.click_button(submit_button_text, visible: :visible) if submit_form
      page.click_link("Continue", visible: :visible) if click_continue
    end

    # Starts from the service root and signs in. The Teacher Auth stub signs every request in,
    # so the dfe-wizard journey is signed out first to go through its `sign_in` step.
    def start_registration_from_root
      if Feature.registration_dfe_wizard?
        allow_any_instance_of(ApplicationController).to receive(:session).and_call_original

        visit("/")
        expect(page).to have_current_path(journey_path("/registration/sign-in"))
        expect(page).to have_text("Before you start")
        page.click_button("Start now")
        expect(page).to have_current_path(journey_path("/registration/course-start-date"))
      else
        navigate_to_page(path: "/", submit_form: false) do
          expect(page).to have_text("Before you start")
          page.click_button("Start now")
        end
      end
    end

    def expect_check_answers_page_to_have_answers(values)
      check_answers_page = CheckAnswersPage.new

      expect(check_answers_page).to be_displayed

      summary_data = check_answers_page.summary_list.rows.map { |summary_item|
        [summary_item.key, summary_item.value]
      }.to_h

      expect(summary_data).to eql(values)
    end

    def expect_applicant_reached_end_of_journey(total_number_of_created_applications: 1)
      expect_page_to_have(path: "/registration/registration-submitted") do
        expect(page).to have_text("Registration submitted")
        expect(page).to have_text("We'll notify your training provider of your registration")
        expect(page).to have_link("View your registration details", href: application_path(latest_application.ecf_id))
      end

      expect(User.count).to be(1)
      expect(Application.count).to be(total_number_of_created_applications)
    end

    def seed_course_cohort_in_registration_store
      course_cohort = CourseCohort.registerable.first
      return unless course_cohort

      page.set_rack_session(
        "registration_store" => {
          "course_cohort_ecf_id" => course_cohort.ecf_id,
        },
      )
    end

    def check_back_journey_is_correct
      starting_path = page.current_path
      until page.current_path == journey_path("/registration/course-start-date")
        page.click_link("Back")
        back_steps ||= []
        back_steps << page.current_path
      end
      expect(back_steps.reverse).to eq @steps_visited
      visit starting_path
    end
  end
end
