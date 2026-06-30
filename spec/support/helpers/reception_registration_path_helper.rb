module Helpers
  module ReceptionRegistrationPathHelper
    def start_registration
      navigate_to_page(path: "/", submit_form: false) do
        page.click_button("Start now")
      end
    end

    def choose_current_course_start_date
      expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
        page.choose(CourseCohort.next_open_for(course: Course.reception).name, visible: :all)
      end
    end

    def choose_provider(lead_provider)
      expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
        page.choose(lead_provider.name, visible: :all)
      end
    end

    def choose_teacher_catchment(answer)
      expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
        page.choose(answer, visible: :all)
      end
    end

    def choose_work_setting(label)
      expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
        page.choose(label, visible: :all)
      end
    end

    def continue_past_ineligible_funding
      expect_page_to_have(path: "/registration/ineligible-for-funding", click_continue: true)
    end

    def choose_course_funding(label)
      expect_page_to_have(path: "/registration/funding-your-course", submit_form: true) do
        page.choose(label, visible: :all)
      end
    end

    def agree_to_share_provider_information
      expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
        page.check("Yes, I agree to share my information", visible: :all)
      end
    end

    def submit_check_answers
      expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true)
    end
  end
end
