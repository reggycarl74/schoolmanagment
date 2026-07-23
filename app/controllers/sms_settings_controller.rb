class SmsSettingsController < ApplicationController
  before_action :require_administrator

  def show
    @school = current_school
  end

  def update
    current_school.assign_attributes(sms_params.except(:sms_auth_token))
    current_school.sms_auth_token = sms_params[:sms_auth_token]
    current_school.save!
    redirect_to sms_setting_path, notice: "SMS configuration was saved securely."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to sms_setting_path, alert: error.record.errors.full_messages.to_sentence
  end

  def test
    SmsDeliveryService.call(
      to: params.require(:test_phone),
      body: "SchoolOS SMS test from #{current_school.name}. Your SMS configuration is working.",
      school: current_school
    )
    redirect_to sms_setting_path, notice: "Test SMS was sent successfully."
  rescue SmsDeliveryService::DeliveryError => error
    redirect_to sms_setting_path, alert: "Test failed: #{error.message}"
  end

  private

  def sms_params
    params.expect(school: %i[sms_enabled sms_account_sid sms_auth_token sms_from_number])
  end
end
