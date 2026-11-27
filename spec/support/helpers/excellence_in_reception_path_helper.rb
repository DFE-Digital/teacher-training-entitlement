module Helpers
  module ExcellenceInReceptionPathHelper
    def start_registration
      seed_reception_course_cohort_in_session

      navigate_to_page(path: "/registrations/#{Course::TTE_EARLY_YEARS}/course-start-date", submit_form: false)
    end

    def choose_current_course_start_date
      expect_page_to_have(path: "/registrations/#{Course::TTE_EARLY_YEARS}/course-start-date", submit_form: true) do
        page.choose(reception_course_cohort.cohort.name, visible: :all)
      end
    end

    def choose_provider(lead_provider)
      expect_page_to_have(path: registration_step_path("choose-your-provider"), submit_form: true) do
        page.choose(lead_provider.name, visible: :all)
      end
    end

    def choose_teacher_catchment(answer)
      expect_page_to_have(path: registration_step_path("teacher-catchment"), submit_form: true) do
        page.choose(answer, visible: :all)
      end
    end

    def choose_a_school(name:, **_options)
      institution = Institution.where("name ILIKE ?", "%#{name}%").first!
      navigate_to_page(path: registration_step_path("choose-school"), submit_form: true) do
        page.all("input[name='choose-school[institution_id]']", visible: :all).map { |field| field.set(institution.id) }
      end
    end

    def choose_work_setting(label)
      expect_page_to_have(path: registration_step_path("work-setting"), submit_form: true) do
        page.choose(label, visible: :all)
      end
    end

    def continue_past_ineligible_funding
      expect_page_to_have(path: page.current_path, click_continue: true)
    end

    def choose_course_funding(label)
      expect_page_to_have(path: registration_step_path("funding-your-course"), submit_form: true) do
        page.choose(label, visible: :all)
      end
    end

    def agree_to_share_provider_information
      expect_page_to_have(path: registration_step_path("share-provider"), submit_form: true) do
        page.check("Yes, I agree to share my information", visible: :all)
      end
    end

    def submit_check_answers
      expect_page_to_have(path: registration_step_path("check-answers"), submit_form: true)
    end

  private

    def registration_step_path(step_slug)
      "/registrations/#{Course::TTE_EARLY_YEARS}/#{step_slug}"
    end

    def reception_course_cohort
      course = Course.reception
      course_cohort = course.course_cohorts.registerable.order(:training_starts_at).offset(1).first
      return course_cohort if course_cohort

      cohort = FactoryBot.create(
        :cohort,
        registration_starts_at: 2.months.ago.to_date.beginning_of_month,
        registration_ends_at: 2.months.from_now.to_date,
      )
      FactoryBot.create(:course_cohort, course:, cohort:, training_starts_at: 6.months.from_now.to_date)
    end

    def seed_reception_course_cohort_in_session
      course_cohort = reception_course_cohort

      page.set_rack_session(
        "registrations" => {
          "course_cohort_ecf_id" => course_cohort.ecf_id,
        },
      )
    end
  end
end
