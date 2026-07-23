require "net/http"
require "uri"

class SmsDeliveryService
  class DeliveryError < StandardError; end

  def self.call(to:, body:, school: nil)
    new(to: to, body: body, school:).call
  end

  def initialize(to:, body:, school: nil)
    @to = to
    @body = body
    @school = school
  end

  def call
    validate_configuration!
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
      http.request(request)
    end
    return response if response.is_a?(Net::HTTPSuccess)

    raise DeliveryError, "SMS provider returned HTTP #{response.code}: #{response.body.to_s.first(300)}"
  end

  private

  def validate_configuration!
    raise DeliveryError, "SMS delivery is disabled in Operations → SMS settings" if @school && !@school.sms_enabled?
    raise DeliveryError, "SMS configuration is incomplete" if account_sid.blank? || auth_token.blank? || from_number.blank?
    raise DeliveryError, "Phone number must use international format, for example +233..." unless @to.to_s.start_with?("+")
  end

  def uri
    @uri ||= URI("https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json")
  end

  def request
    Net::HTTP::Post.new(uri).tap do |post|
      post.basic_auth(account_sid, auth_token)
      post.set_form_data(To: @to, From: from_number, Body: @body)
    end
  end

  def account_sid = @school&.sms_account_sid.presence || ENV["TWILIO_ACCOUNT_SID"]
  def auth_token = @school&.sms_auth_token.presence || ENV["TWILIO_AUTH_TOKEN"]
  def from_number = @school&.sms_from_number.presence || ENV["TWILIO_FROM_NUMBER"]
end
