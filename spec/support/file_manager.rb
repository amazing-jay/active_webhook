# frozen_string_literal: true

module FileManager
  def config_file
    "#{Rails.root}/config/active_webhook.rb"
  end

  def remove_config
    FileUtils.remove_file config_file if File.file?(config_file)
  end

  def migration_files
    Dir.glob("#{Rails.root}/db/migrate/*create_active_webhook_tables.rb")
  end

  def remove_migrations
    migration_files.each do |migration_file|
      if File.file?(migration_file) && !migration_file.end_with?("20210618023338_create_active_webhook_tables.rb")
        FileUtils.remove_file migration_file
      end
    end
  end
end
