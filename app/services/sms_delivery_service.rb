require "net/http"
require "uri"

class SmsDeliveryService
  class DeliveryError < StandardError; end

  def self.call(to:, body:)
    new(to: to, body: body).call
  end

  def initialize(to:, body:)
    @to = to
    @body = body
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
    missing = %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_FROM_NUMBER].select { |name| ENV[name].blank? }
    raise DeliveryError, "Missing SMS configuration: #{missing.join(', ')}" if missing.any?
    raise DeliveryError, "Guardian phone must use international format, for example +233..." unless @to.to_s.start_with?("+")
  end

  def uri
    @uri ||= URI("https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch('TWILIO_ACCOUNT_SID')}/Messages.json")
  end

  def request
    Net::HTTP::Post.new(uri).tap do |post|
      post.basic_auth(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
      post.set_form_data(To: @to, From: ENV.fetch("TWILIO_FROM_NUMBER"), Body: @body)
    end
  end
end
