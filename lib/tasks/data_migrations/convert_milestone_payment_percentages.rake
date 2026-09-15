namespace :data_migrations do
  desc "Convert milestone payment percentages from whole percentages to decimal ratios"
  task :convert_milestone_payment_percentages, %i[dry_run] => :environment do |_task, args|
    dry_run = args[:dry_run] != "false"
    converted_count = 0

    Milestone.where("payment_percentage > 1").find_each do |milestone|
      old_payment_percentage = milestone.payment_percentage
      new_payment_percentage = old_payment_percentage / 100

      puts "Milestone #{milestone.id}: payment_percentage #{old_payment_percentage} -> #{new_payment_percentage}"
      milestone.update_columns(payment_percentage: new_payment_percentage) unless dry_run

      converted_count += 1
    end

    puts "Dry run: #{dry_run}"
    puts "Converted milestones: #{converted_count}"
  end
end
