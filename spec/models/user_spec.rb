require "rails_helper"

RSpec.describe "User" do
  def marshal_with_class_renamed(object, from:, to:)
    Marshal.dump(object).gsub(":#{(from.length + 5).chr}#{from}", ":#{(to.length + 5).chr}#{to}")
  end

  let(:teacher) { create(:teacher) }

  it "loads a Marshal-serialised User as a Teacher" do
    payload = marshal_with_class_renamed(teacher, from: "Teacher", to: "User")
    expect(payload).not_to include("Teacher")

    expect(Marshal.load(payload)).to eq(teacher) # rubocop:disable Security/MarshalLoad
  end

  it "loads a Marshal-serialised NullUser as a NullTeacher" do
    payload = marshal_with_class_renamed(NullTeacher.new, from: "NullTeacher", to: "NullUser")
    expect(payload).not_to include("Teacher")

    expect(Marshal.load(payload)).to be_a(NullTeacher) # rubocop:disable Security/MarshalLoad
  end

  it "locates a User global ID as a Teacher" do
    expect(GlobalID::Locator.locate("gid://#{GlobalID.app}/User/#{teacher.id}")).to eq(teacher)
  end

  it "deserialises a queued RefreshUserTokenJob as a RefreshTeacherTokenJob" do
    job_data = RefreshTeacherTokenJob.new(teacher).serialize.merge(
      "job_class" => "RefreshUserTokenJob",
      "arguments" => [{ "_aj_globalid" => "gid://#{GlobalID.app}/User/#{teacher.id}" }],
    )

    job = ActiveJob::Base.deserialize(job_data)
    job.send(:deserialize_arguments_if_needed)

    expect(job).to be_a(RefreshTeacherTokenJob)
    expect(job.arguments).to eq([teacher])
  end
end
