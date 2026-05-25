#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "fileutils"
require "json"
require "net/http"
require "openssl"
require "uri"

ISSUER_ID = "69a6de78-ba5a-47e3-e053-5b8c7c11a4d1"
KEY_ID = "WZBYHD6QVD"
KEY_PATH = File.expand_path("../../永久列管/AuthKey_WZBYHD6QVD.p8", __dir__)
BUNDLE_ID = "com.yushang.poseframe3d"
PROFILE_NAME = "PoseFrame Studio App Store"
PROFILE_TYPE = "IOS_APP_STORE"

class AppStoreConnectClient
  API_BASE = "https://api.appstoreconnect.apple.com"

  def initialize
    @private_key = OpenSSL::PKey.read(File.read(KEY_PATH))
  end

  def get(path, query = {})
    request(:get, path, query: query)
  end

  def post(path, body)
    request(:post, path, body: body)
  end

  private

  def request(method, path, query: {}, body: nil)
    uri = URI("#{API_BASE}#{path}")
    uri.query = URI.encode_www_form(query) unless query.empty?
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{jwt}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body) if body

    response = http.request(request)
    parsed = response.body.empty? ? {} : JSON.parse(response.body)
    return parsed if response.code.to_i.between?(200, 299)

    raise "App Store Connect API #{method.upcase} #{path} failed #{response.code}: #{JSON.pretty_generate(parsed)}"
  end

  def jwt
    now = Time.now.to_i
    header = { alg: "ES256", kid: KEY_ID, typ: "JWT" }
    payload = { iss: ISSUER_ID, iat: now, exp: now + 1200, aud: "appstoreconnect-v1" }
    signing_input = [base64_json(header), base64_json(payload)].join(".")
    der_signature = @private_key.sign(OpenSSL::Digest::SHA256.new, signing_input)
    raw_signature = OpenSSL::ASN1.decode(der_signature).value.map do |integer|
      bytes = integer.value.to_s(2)
      ("\x00" * (32 - bytes.bytesize) + bytes)[-32, 32]
    end.join
    [signing_input, base64(raw_signature)].join(".")
  end

  def base64_json(object)
    base64(JSON.generate(object))
  end

  def base64(value)
    Base64.urlsafe_encode64(value).delete("=")
  end
end

def first_data(response)
  response.fetch("data", []).first
end

client = AppStoreConnectClient.new
bundle = first_data(client.get("/v1/bundleIds", "filter[identifier]" => BUNDLE_ID))
raise "Bundle ID #{BUNDLE_ID} does not exist" unless bundle

certificate = client.get("/v1/certificates", "limit" => "50").fetch("data").find do |item|
  item.dig("attributes", "certificateType") == "DISTRIBUTION" &&
    item.dig("attributes", "name").to_s.include?("Apple Distribution")
end
raise "No Apple Distribution certificate is available through this API key" unless certificate

existing = first_data(client.get(
  "/v1/profiles",
  "filter[name]" => PROFILE_NAME,
  "filter[profileType]" => PROFILE_TYPE,
  "limit" => "10"
))

profile = existing || client.post(
  "/v1/profiles",
  data: {
    type: "profiles",
    attributes: {
      name: PROFILE_NAME,
      profileType: PROFILE_TYPE
    },
    relationships: {
      bundleId: {
        data: {
          type: "bundleIds",
          id: bundle.fetch("id")
        }
      },
      certificates: {
        data: [
          {
            type: "certificates",
            id: certificate.fetch("id")
          }
        ]
      }
    }
  }
).fetch("data")

content = profile.dig("attributes", "profileContent")
raise "Profile #{PROFILE_NAME} has no profileContent" unless content

local_dir = File.expand_path("../Build/profiles", __dir__)
install_dir = File.expand_path("~/Library/MobileDevice/Provisioning Profiles")
FileUtils.mkdir_p(local_dir)
FileUtils.mkdir_p(install_dir)

profile_filename = "#{profile.fetch('id')}.mobileprovision"
local_path = File.join(local_dir, profile_filename)
install_path = File.join(install_dir, profile_filename)
File.binwrite(local_path, Base64.decode64(content))
FileUtils.cp(local_path, install_path)

puts("Profile id: #{profile.fetch('id')}")
puts("Profile name: #{PROFILE_NAME}")
puts("Installed: #{install_path}")
