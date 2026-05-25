#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "shellwords"

ROOT = File.expand_path("..", __dir__)
BUNDLE_ID = "com.yushang.poseframe3d"
PRODUCT_ID = "com.yushang.poseframe3d.pro"
OWNER = "kingboss568"
REPO = "poseframe-3d-ios"
PAGES_BASE = "https://#{OWNER}.github.io/#{REPO}"

def read(path)
  File.read(File.join(ROOT, path))
end

def assert(condition, message)
  raise "FAIL: #{message}" unless condition
  puts "PASS: #{message}"
end

def assert_file(path)
  assert(File.file?(File.join(ROOT, path)), "#{path} exists")
end

project = read("PoseReferenceApp.xcodeproj/project.pbxproj")
listing = read("AppStore/AppStoreListing.zh-Hant.md")
review = read("AppStore/ReviewNotes.zh-Hant.md")
checklist = read("AppStore/ComplianceChecklist.zh-Hant.md")
privacy = read("AppStore/PrivacyPolicy.zh-Hant.md")
content = read("PoseReferenceApp/Views/ContentView.swift")
app_state = read("PoseReferenceApp/State/AppState.swift")
privacy_manifest_path = File.join(ROOT, "PoseReferenceApp/Resources/PrivacyInfo.xcprivacy")

assert(project.include?("PRODUCT_BUNDLE_IDENTIFIER = #{BUNDLE_ID};"), "Xcode project uses #{BUNDLE_ID}")
assert(listing.include?("Bundle ID：#{BUNDLE_ID}"), "listing Bundle ID matches project")
assert(app_state.include?(%Q(static let proProductID = "#{PRODUCT_ID}")), "StoreKit product id is #{PRODUCT_ID}")
assert(listing.include?(PRODUCT_ID), "listing mentions IAP product id")
assert(review.include?(PRODUCT_ID), "review notes mention IAP product id")
assert(!review.include?("無 IAP"), "review notes do not claim there is no IAP")
assert(checklist.include?(BUNDLE_ID), "compliance checklist uses current Bundle ID")
assert(!checklist.include?("com.poseframe3d.referenceapp"), "compliance checklist does not mention old Bundle ID")
assert(![listing, review, checklist].join("\n").include?("無 IAP"), "App Store docs do not claim there is no IAP")

assert_file("AppStore/Support.zh-Hant.md")
assert_file("docs/privacy.html")
assert_file("docs/support.html")
assert(privacy.include?("jushiung@gmail.com"), "privacy policy has real contact email")
assert(content.include?(PAGES_BASE), "app contains public GitHub Pages support/privacy URLs")

assert_file("fastlane/Fastfile")
assert_file("fastlane/Appfile")
assert_file("fastlane/Deliverfile")
assert_file("fastlane/metadata/zh-Hant/description.txt")
assert_file("fastlane/metadata/zh-Hant/privacy_url.txt")
assert_file("fastlane/metadata/zh-Hant/support_url.txt")
assert_file("fastlane/metadata/zh-Hant/review_information/demo_user.txt")

assert_file("AppStore/IAP.json")
iap = JSON.parse(read("AppStore/IAP.json"))
assert(iap.fetch("product_id") == PRODUCT_ID, "IAP JSON product id matches app")
assert(iap.fetch("type") == "non_consumable", "IAP JSON uses non-consumable product type")

%w[iphone69 ipad13].each do |device|
  dir = File.join(ROOT, "Screenshots", device)
  screenshots = Dir.glob(File.join(dir, "*.png")).reject { |path| File.basename(path).start_with?("._") }
  assert(screenshots.size >= 6, "#{device} has at least 6 PNG screenshots")
  screenshots.each do |path|
    dimensions = `sips -g pixelWidth -g pixelHeight #{path.shellescape} 2>/dev/null`
    assert($?.success? && dimensions.include?("pixelWidth:"), "#{File.basename(path)} is a readable PNG")
  end
end

privacy_manifest = `plutil -lint #{privacy_manifest_path.shellescape} 2>&1`
assert($?.success?, "PrivacyInfo.xcprivacy passes plutil")
