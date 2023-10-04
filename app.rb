require 'bandwidth-sdk'

begin
  BW_ACCOUNT_ID = ENV.fetch('BW_ACCOUNT_ID')
  BW_USERNAME = ENV.fetch('BW_USERNAME')
  BW_PASSWORD = ENV.fetch('BW_PASSWORD')
  BW_NUMBER = ENV.fetch('BW_NUMBER')
  BW_VOICE_APPLICATION_ID = ENV.fetch('BW_VOICE_APPLICATION_ID')
  BW_MESSAGING_APPLICATION_ID = ENV.fetch('BW_MESSAGING_APPLICATION_ID')
rescue StandardError
  puts 'Please set the environmental variables defined in the README'
  exit(-1)
end

Bandwidth.configure do |config| # Configure Basic Auth
  config.username = BW_USERNAME
  config.password = BW_PASSWORD
end

mfa_api_instance = Bandwidth::MFAApi.new

puts 'Enter phone number in E164 format (+15554443333): '
recipient_phone_number = gets.chomp

puts 'Enter MFA request method (voice/messaging). Default is messaging: '
delivery_method = gets.chomp

code_request_body = Bandwidth::CodeRequest.new(
  to: recipient_phone_number,
  from: BW_NUMBER,
  application_id: delivery_method == 'voice' ? BW_VOICE_APPLICATION_ID : BW_MESSAGING_APPLICATION_ID,
  scope: 'scope',
  message: 'Your temporary {NAME} {SCOPE} code is {CODE}',
  digits: 6
)

if delivery_method == 'voice'
  mfa_api_instance.generate_voice_code(BW_ACCOUNT_ID, code_request_body)
else
  mfa_api_instance.generate_messaging_code(BW_ACCOUNT_ID, code_request_body)
end

puts 'Please enter your received code: '
code = gets.chomp

verify_request_body = Bandwidth::VerifyCodeRequest.new(
  to: recipient_phone_number,
  scope: 'scope',
  code: code,
  expiration_time_in_minutes: 3
)

mfa_api_instance.verify_code(BW_ACCOUNT_ID, verify_request_body).valid ? puts('Success!') : puts('Failure')
