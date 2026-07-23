class AddSourceToNotificationDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_reference :notification_deliveries, :source, polymorphic: true, index: true
  end
end
