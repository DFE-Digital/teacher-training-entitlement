require "csv"

namespace :delivery_partners do
  namespace :partners do
    desc "Import delivery partners from csv"
    task :import, %i[import_file dry_run] => :environment do |_t, args|
      Rails.logger = Logger.new($stdout) unless Rails.env.test?

      raise "Import file not specified" if args[:import_file].blank?
      raise "Import file not present" unless File.exist?(args[:import_file])
      raise "Import file is empty" if File.size(args[:import_file]).zero?

      DeliveryPartner.transaction do
        raise "Delivery Partners already exist" unless DeliveryPartner.count.zero?

        CSV.foreach(args[:import_file], headers: true) do |row|
          DeliveryPartner.create!(ecf_id: row["ECF Id"], name: row["Name"])
        end

        unless args[:dry_run] == "false"
          Rails.logger.info \
            "DRY RUN: Imported #{DeliveryPartner.count} Delivery Partners, now rolling back"

          raise ActiveRecord::Rollback
        end
      end
    end

    desc "Export all delivery partners to a csv"
    task :export, %i[export_file] => :environment do |_t, args|
      raise "Export file not specified" if args[:export_file].blank?

      CSV.open(args[:export_file], "w") do |csv|
        csv << ["ECF Id", "Name"]

        DeliveryPartner.order(id: :asc).find_each do |delivery_partner|
          csv << [delivery_partner.ecf_id, delivery_partner.name]
        end
      end
    end
  end

  namespace :partnerships do
    desc "Import delivery partnerships from csv"
    task :import, %i[import_file dry_run] => :environment do |_t, args|
      Rails.logger = Logger.new($stdout) unless Rails.env.test?

      raise "Import file not specified" if args[:import_file].blank?
      raise "Import file not present" unless File.exist?(args[:import_file])
      raise "Import file is empty" if File.size(args[:import_file]).zero?

      expected_headers = ["Lead Provider ECF Id", "Course Identifier", "Delivery Partner ECF Id"]
      headers = CSV.open(args[:import_file], &:readline).to_a
      missing_headers = expected_headers - headers
      if missing_headers.any?
        raise "Import file is missing expected column(s): #{missing_headers.join(', ')}"
      end

      created = 0
      skipped = 0

      DeliveryPartnership.transaction do
        lead_providers = LeadProvider.all.index_by(&:ecf_id)
        courses = Course.all.index_by(&:identifier)
        delivery_partners = DeliveryPartner.all.index_by(&:ecf_id)

        CSV.foreach(args[:import_file], headers: true).with_index(2) do |row, line|
          lead_provider = lead_providers[row["Lead Provider ECF Id"]]
          course = courses[row["Course Identifier"]]
          delivery_partner = delivery_partners[row["Delivery Partner ECF Id"]]

          unknown = []
          unknown << "Lead Provider ECF Id '#{row['Lead Provider ECF Id']}'" unless lead_provider
          unknown << "Course Identifier '#{row['Course Identifier']}'" unless course
          unknown << "Delivery Partner ECF Id '#{row['Delivery Partner ECF Id']}'" unless delivery_partner

          if unknown.any?
            skipped += 1
            Rails.logger.info "Row #{line} skipped: unknown #{unknown.join(', ')}"
            next
          end

          partnership = DeliveryPartnership.find_or_create_by!(lead_provider:, course:, delivery_partner:)
          created += 1 if partnership.previously_new_record?
        end

        unless args[:dry_run] == "false"
          Rails.logger.info \
            "DRY RUN: Imported #{created} Delivery Partnerships (#{skipped} skipped), now rolling back"

          raise ActiveRecord::Rollback
        end
      end
    end

    desc "Export all delivery partnerships to a csv"
    task :export, %i[export_file] => :environment do |_t, args|
      raise "Export file not specified" if args[:export_file].blank?

      CSV.open(args[:export_file], "w") do |csv|
        csv << ["Lead Provider ECF Id", "Course Identifier", "Delivery Partner ECF Id"]

        DeliveryPartnership
            .order(id: :asc)
            .includes(:lead_provider, :course, :delivery_partner)
            .find_each(batch_size: 500) do |partnership|
          csv << [
            partnership.lead_provider.ecf_id,
            partnership.course.identifier,
            partnership.delivery_partner.ecf_id,
          ]
        end
      end
    end
  end
end
