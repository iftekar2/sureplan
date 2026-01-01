require 'jwt'
require 'openssl'

# --- CONFIGURATION ---
# Replace these with your actual values
TEAM_ID = 'TDA525W888' 
CLIENT_ID = 'com.example.sureplan' # Should match the one in Supabase
KEY_ID = 'MF92YJ7T7C'
KEY_FILE_PATH = 'ios/Runner/AuthKey_MF92YJ7T7C.p8'
# ---------------------

begin
  private_key_content = File.read(KEY_FILE_PATH)
  private_key = OpenSSL::PKey::EC.new(private_key_content)

  # Apple Client Secrets are valid for a maximum of 6 months (15777000 seconds)
  validity_period = 15777000 

  payload = {
    iss: TEAM_ID,
    iat: Time.now.to_i,
    exp: Time.now.to_i + validity_period,
    aud: 'https://appleid.apple.com',
    sub: CLIENT_ID
  }

  headers = {
    kid: KEY_ID,
    typ: 'JWT',
    alg: 'ES256'
  }

  token = JWT.encode(payload, private_key, 'ES256', headers)

  puts "\n--- YOUR GENERATED JWT (CLIENT SECRET) ---"
  puts token
  puts "-------------------------------------------\n"
  puts "Copy the long string above and paste it into the 'Secret Key' field in Supabase."

rescue Errno::ENOENT
  puts "Error: Could not find the .p8 file at #{KEY_FILE_PATH}"
rescue OpenSSL::PKey::PKeyError
  puts "Error: The contents of the .p8 file are not a valid EC private key."
rescue LoadError
  puts "Error: the 'jwt' gem is not installed. Run 'gem install jwt' first."
rescue => e
  puts "An unexpected error occurred: #{e.message}"
end
