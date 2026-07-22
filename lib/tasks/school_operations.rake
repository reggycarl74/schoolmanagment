namespace :school do
  desc "Create a timestamped MySQL backup in backups/"
  task backup: :environment do
    configuration = ActiveRecord::Base.connection_db_config.configuration_hash
    backup_directory = Rails.root.join("backups")
    FileUtils.mkdir_p(backup_directory)
    destination = backup_directory.join("school-#{Time.current.utc.strftime('%Y%m%d%H%M%S')}.sql")
    arguments = [ "mysqldump", "--single-transaction", "--host=#{configuration[:host] || '127.0.0.1'}", "--user=#{configuration[:username]}", configuration[:database] ]
    environment = configuration[:password].present? ? { "MYSQL_PWD" => configuration[:password].to_s } : {}
    File.open(destination, "w") do |file|
      abort "Backup failed. Make sure mysqldump is installed." unless system(environment, *arguments, out: file)
    end
    puts "Backup created at #{destination}"
  end

  desc "Remove old security and notification logs (RETENTION_DAYS defaults to 365)"
  task purge_old_logs: :environment do
    cutoff = ENV.fetch("RETENTION_DAYS", 365).to_i.days.ago
    puts "Removed #{LoginActivity.where(created_at: ...cutoff).delete_all} login activities"
    puts "Removed #{NotificationDelivery.where(created_at: ...cutoff).delete_all} notification deliveries"
    puts "Removed #{AuditEvent.where(created_at: ...cutoff).delete_all} audit events"
  end
end
