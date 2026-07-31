namespace :data_migrations do
  desc "Backfill statement and declaration data for ticket #630"
  task :backfill_statement_data, [:dry_run] => :environment do |_task, args|
    dry_run = ActiveModel::Type::Boolean.new.cast(args[:dry_run])
    updated_statement_count = 0
    skipped_statement_count = 0
    updated_declaration_count = 0
    skipped_declaration_count = 0

    Statement.where(start_date: nil).find_each do |statement|
      unless statement[:month] && statement[:year]
        skipped_statement_count += 1
        next
      end

      statement.update_columns(start_date: Date.new(statement[:year], statement[:month], 1), frequency: "monthly") unless dry_run
      updated_statement_count += 1
    end

    Declaration.where(statement_id: nil).find_each do |declaration|
      statement_item = StatementItem.find_by(declaration_id: declaration.id)

      unless statement_item
        skipped_declaration_count += 1
        next
      end

      declaration.update_columns(statement_id: statement_item.statement_id) unless dry_run
      updated_declaration_count += 1
    end

    unless Rails.env.test?
      puts "DRY RUN: no records were changed" if dry_run
      puts "Updated #{updated_statement_count} statements"
      puts "Skipped #{skipped_statement_count} statements (no month/year)"
      puts "Updated #{updated_declaration_count} declarations"
      puts "Skipped #{skipped_declaration_count} declarations (no statement_item)"
    end
  end
end
