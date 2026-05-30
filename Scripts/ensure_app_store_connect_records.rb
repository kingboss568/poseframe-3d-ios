#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"

ISSUER_ID = "69a6de78-ba5a-47e3-e053-5b8c7c11a4d1"
KEY_ID = "WZBYHD6QVD"
KEY_PATH = File.expand_path("../../永久列管/AuthKey_WZBYHD6QVD.p8", __dir__)
BUNDLE_ID = "com.yushang.poseframe3d"
APP_NAME = "PoseFrame Studio"
SKU = "com.yushang.poseframe3d"
IAP_PRODUCT_ID = "com.yushang.poseframe3d.pro"

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

def create_bundle_id(client)
  existing = first_data(client.get("/v1/bundleIds", "filter[identifier]" => BUNDLE_ID))
  return existing if existing

  puts("Creating Bundle ID #{BUNDLE_ID}")
  client.post(
    "/v1/bundleIds",
    data: {
      type: "bundleIds",
      attributes: {
        identifier: BUNDLE_ID,
        name: APP_NAME,
        platform: "IOS"
      }
    }
  ).fetch("data")
end

def create_app(client, bundle)
  existing = first_data(client.get("/v1/apps", "filter[bundleId]" => BUNDLE_ID))
  return existing if existing

  puts("Creating App Store Connect app #{APP_NAME}")
  client.post(
    "/v1/apps",
    data: {
      type: "apps",
      attributes: {
        bundleId: BUNDLE_ID,
        name: APP_NAME,
        primaryLocale: "zh-Hant",
        sku: SKU
      },
      relationships: {
        bundleId: {
          data: {
            type: "bundleIds",
            id: bundle.fetch("id")
          }
        }
      }
    }
  ).fetch("data")
end

def create_iap(client, app)
  existing = first_data(client.get("/v1/apps/#{app.fetch('id')}/inAppPurchasesV2", "filter[productId]" => IAP_PRODUCT_ID))
  return existing if existing

  puts("Creating non-consumable IAP #{IAP_PRODUCT_ID}")
  client.post(
    "/v2/inAppPurchases",
    data: {
      type: "inAppPurchases",
      attributes: {
        name: "PoseFrame Studio Pro",
        productId: IAP_PRODUCT_ID,
        inAppPurchaseType: "NON_CONSUMABLE",
        familySharable: true
      },
      relationships: {
        app: {
          data: {
            type: "apps",
            id: app.fetch("id")
          }
        }
      }
    }
  ).fetch("data")
end

def create_iap_localization(client, iap, locale, name, description)
  client.post(
    "/v1/inAppPurchaseLocalizations",
    data: {
      type: "inAppPurchaseLocalizations",
      attributes: {
        locale: locale,
        name: name,
        description: description
      },
      relationships: {
        inAppPurchaseV2: {
          data: {
            type: "inAppPurchases",
            id: iap.fetch("id")
          }
        }
      }
    }
  )
  puts("Created IAP localization #{locale}")
rescue StandardError => error
  raise unless error.message.include?("409") || error.message.include?("ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE")
  puts("IAP localization #{locale} already exists")
end

client = AppStoreConnectClient.new
bundle = create_bundle_id(client)
app = create_app(client, bundle)
iap = create_iap(client, app)

create_iap_localization(
  client,
  iap,
  "zh-Hant",
  "PoseFrame Studio Pro",
  "一次解鎖商稿角色、進階姿勢、構圖輔助、透明 PNG 與多視角輸出。"
)

create_iap_localization(
  client,
  iap,
  "en-US",
  "PoseFrame Studio Pro",
  "One-time unlock for editorial characters, advanced poses, composition guides, transparent PNG export, and multi-angle references."
)

puts("ASC app id: #{app.fetch('id')}")
puts("ASC IAP id: #{iap.fetch('id')}")
puts("Reminder: set IAP price schedule and attach the IAP to the app version before final review submission if the API reports missing pricing.")
