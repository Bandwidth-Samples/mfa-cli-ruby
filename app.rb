require 'bandwidth-sdk'

begin
  BW_ACCOUNT_ID = ENV.fetch('BW_ACCOUNT_ID')
  BW_CLIENT_ID = ENV.fetch('BW_CLIENT_ID')
  BW_CLIENT_SECRET = ENV.fetch('BW_CLIENT_SECRET')
  BW_NUMBER = ENV.fetch('BW_NUMBER')
  BW_VOICE_APPLICATION_ID = ENV.fetch('BW_VOICE_APPLICATION_ID')
  BW_MESSAGING_APPLICATION_ID = ENV.fetch('BW_MESSAGING_APPLICATION_ID')
rescue StandardError
  puts 'Please set the environmental variables defined in the README'
  exit(-1)
end

Bandwidth.configure do |config|
  config.client_id = BW_CLIENT_ID
  config.client_secret = BW_CLIENT_SECRET
end

$stdout.sync = true

E164_PATTERN = /\A\+[1-9]\d{1,14}\z/
SCOPE = 'sample'.freeze

def prompt(text)
  print text
  line = $stdin.gets
  exit(1) if line.nil?
  line.strip
end

phone_number = prompt('Enter the phone number to send the code to (E.164, e.g. +15554443333): ')
unless phone_number.match?(E164_PATTERN)
  warn 'Phone number must be in E.164 format, e.g. +15554443333'
  exit(1)
end

method = prompt('Send the code by messaging or voice? [messaging]: ').downcase
method = 'messaging' if method.empty?
unless %w[messaging voice].include?(method)
  warn 'Method must be messaging or voice'
  exit(1)
end

mfa_api = Bandwidth::MFAApi.new

code_request = Bandwidth::CodeRequest.new(
  to: phone_number,
  from: BW_NUMBER,
  application_id: method == 'voice' ? BW_VOICE_APPLICATION_ID : BW_MESSAGING_APPLICATION_ID,
  scope: SCOPE,
  message: 'Your temporary {NAME} {SCOPE} code is {CODE}',
  digits: 6
)

puts "Sending a code by #{method} to #{phone_number}"
begin
  if method == 'voice'
    mfa_api.generate_voice_code(BW_ACCOUNT_ID, code_request)
  else
    mfa_api.generate_messaging_code(BW_ACCOUNT_ID, code_request)
  end
rescue StandardError => e
  warn "Failed to send code: #{e.message}"
  exit(1)
end

verify_request = Bandwidth::VerifyCodeRequest.new(
  to: phone_number,
  scope: SCOPE,
  expiration_time_in_minutes: 3,
  code: prompt('Enter the code you received: ')
)

begin
  valid = mfa_api.verify_code(BW_ACCOUNT_ID, verify_request).valid
rescue StandardError => e
  warn "Failed to verify code: #{e.message}"
  exit(1)
end

puts valid ? 'Code verified' : 'Code not verified'
exit(valid ? 0 : 1)
