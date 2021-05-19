#
#app.rb
#
#2FA CLI sample app using Bandwidth's 2FA API
require 'bandwidth'

include Bandwidth
include Bandwidth::TwoFactorAuth

begin
    BW_USERNAME = ENV.fetch('BW_USERNAME')
    BW_PASSWORD = ENV.fetch('BW_PASSWORD')
    BW_ACCOUNT_ID = ENV.fetch('BW_ACCOUNT_ID')
    BW_NUMBER = ENV.fetch('BW_NUMBER')
    BW_VOICE_APPLICATION_ID = ENV.fetch('BW_VOICE_APPLICATION_ID')
    BW_MESSAGING_APPLICATION_ID = ENV.fetch('BW_MESSAGING_APPLICATION_ID')
rescue
    puts "Please set the environmental variables defined in the README"
    exit(-1)
end

bandwidth_client = Bandwidth::Client.new(
    two_factor_auth_basic_auth_user_name: BW_USERNAME,
    two_factor_auth_basic_auth_password: BW_PASSWORD
)
auth_client = bandwidth_client.two_factor_auth_client.mfa

puts "Please enter your phone number in E164 format (+15554443333): "
input = gets
recipient_phone_number = input.chomp
puts "Select your method to receive your 2FA request. Please enter \"voice\" or \"messaging\": "
input = gets
delivery_method = input.chomp

if delivery_method == "messaging"
    from_phone = BW_NUMBER
    to_phone = recipient_phone_number
    application_id = BW_MESSAGING_APPLICATION_ID
    scope = "scope"
    digits = 6

    body = TwoFactorCodeRequestSchema.new
    body.from = from_phone
    body.to = to_phone
    body.application_id = application_id
    body.scope = scope
    body.digits = digits
    body.message = "Your temporary {NAME} {SCOPE} code is {CODE}"

    auth_client.create_messaging_two_factor(BW_ACCOUNT_ID, body)  

    puts "Please enter your received code: "
    input = gets
    code = input.chomp 

    body = TwoFactorVerifyRequestSchema.new
    body.to = to_phone
    body.application_id = application_id
    body.scope = scope
    body.code = code
    body.expiration_time_in_minutes = 3

    response = auth_client.create_verify_two_factor(BW_ACCOUNT_ID, body)

    if response.data.valid
        puts "Success!"
    else
        puts "Failure"
    end
else
    from_phone = BW_NUMBER
    to_phone = recipient_phone_number
    application_id = BW_VOICE_APPLICATION_ID
    scope = "scope"
    digits = 6

    body = TwoFactorCodeRequestSchema.new
    body.from = from_phone
    body.to = to_phone
    body.application_id = application_id
    body.scope = scope
    body.digits = digits
    body.message = "Your temporary {NAME} {SCOPE} code is {CODE}"

    auth_client.create_voice_two_factor(BW_ACCOUNT_ID, body)

    puts "Please enter your received code: "
    input = gets
    code = input.chomp

    body = TwoFactorVerifyRequestSchema.new
    body.to = to_phone
    body.application_id = application_id
    body.scope = scope
    body.code = code
    body.expiration_time_in_minutes = 3

    response = auth_client.create_verify_two_factor(BW_ACCOUNT_ID, body)

    if response.data.valid
        print("Success!")
    else
        print("Failure")
    end
end
