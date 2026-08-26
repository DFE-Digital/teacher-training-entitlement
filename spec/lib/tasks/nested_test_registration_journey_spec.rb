require "rails_helper"

RSpec.describe "registration_journeys:create_nested_test_journey" do
  subject(:run_task) do
    Rake::Task["registration_journeys:create_nested_test_journey"].invoke
  end

  after do
    Rake::Task["registration_journeys:create_nested_test_journey"].reenable
  end

  it "recreates the journey dumped from journey ID 44 with remapped step references" do
    run_task

    journey = RegistrationJourney.find_by!(slug: "nested-test")
    steps = journey.registration_steps
    spicy_continent = steps.find_by!(slug: "what-spicy-continent")

    expect(journey.attributes.slice("name", "slug")).to eq(
      "name" => "Nested test",
      "slug" => "nested-test",
    )
    expect(steps.count).to eq(5)
    expect(steps.pluck(:order)).to eq((1..5).to_a)
    expect(steps.where(slug: %w[what-sri-lanka-curry what-indian-curry]).map(&:previous_step_id))
      .to contain_exactly(spicy_continent.id, spicy_continent.id)
  end

  it "replaces an existing journey with the dumped slug" do
    existing_journey = RegistrationJourney.create!(name: "Old nested test", slug: "nested-test")

    expect { run_task }.not_to change(RegistrationJourney, :count)

    expect(RegistrationJourney.find_by!(slug: "nested-test").id).not_to eq(existing_journey.id)
  end
end
