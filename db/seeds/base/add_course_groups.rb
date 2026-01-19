%w[
  reception
].each do |name|
  FactoryBot.create(:course_group, name:)
end
