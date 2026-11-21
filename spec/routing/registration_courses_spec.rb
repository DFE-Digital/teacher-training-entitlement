require "rails_helper"

RSpec.describe "Registration course routes", type: :routing do
  it "sends a legacy dashed step to the legacy controller" do
    expect(get: "/registration/course-start-date").to route_to("registration_wizard#show", step: "course-start-date")
  end

  it "sends a course identifier to the deep link" do
    expect(get: "/registration/tte-early-years").to route_to("registration/courses#show", course_identifier: "tte-early-years")
  end
end
