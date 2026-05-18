namespace :data_migrations do
  desc "Update provider url and hint"
  task migrate_lead_provider_details: :environment do
    urls = {
      "Ambition Institute" => "https://www.ambition.org.uk/",
      "Best Practice Network" => "https://www.bestpracticenet.co.uk/",
      "UCL Institute of Education" => "https://www.ucl.ac.uk/ioe/",
      "Teach First" => "https://www.teachfirst.org.uk/",
      "National Institute of Teaching" => "https://niot.org.uk/",
      "LLSE" => "https://www.llse.org.uk/",
    }

    hints = {
      "Ambition Institute" => "Ambition Institute is a graduate school with programmes designed to support educators throughout the education sector, including teachers, leaders, and executive leaders.",
      "Best Practice Network" => "We share the desire of every practitioner that every child, regardless of their background, should benefit from an excellent education.",
      "UCL Institute of Education" => "We work across education, culture, psychology and social science to create lasting and evolving change.",
      "Teach First" => "We train and support brilliant people to become teachers and leaders in schools serving the most deprived communities ",
      "National Institute of Teaching" => "We research and run professional development for teachers and school leaders for the benefit of pupils across England. #traintoteach",
      "LLSE" => "An Outstanding Lead Provider of National Professional Qualifications (NPQs) for School Leadership",
    }

    LeadProvider.where(url: nil).find_each do |lead_provider|
      url = urls[lead_provider.name]

      if url
        puts "Updating #{lead_provider.name} with #{url}"
        lead_provider.update!(url:, hint: hints[lead_provider.name])
      else
        puts "Cannot find url for #{lead_provider.name}"
      end
    end
  end
end
