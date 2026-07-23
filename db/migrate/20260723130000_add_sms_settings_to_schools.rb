class AddSmsSettingsToSchools < ActiveRecord::Migration[8.0]
  def change
    change_table :schools, bulk: true do |t|
      t.boolean :sms_enabled, null: false, default: true
      t.string :sms_account_sid
      t.text :sms_auth_token_ciphertext
      t.string :sms_from_number
    end
  end
end
