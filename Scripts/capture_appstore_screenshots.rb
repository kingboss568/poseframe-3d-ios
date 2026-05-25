#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
PROJECT = File.join(ROOT, "PoseReferenceApp.xcodeproj")
SCHEME = "PoseReferenceApp"
BUNDLE_ID = "com.yushang.poseframe3d"

DEVICES = [
  {
    folder: "iphone69",
    prefix: "iphone69",
    name: "PoseFrame-iPhone-6.9",
    type: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"
  },
  {
    folder: "ipad13",
    prefix: "ipad13",
    name: "PoseFrame-iPad-13",
    type: "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB"
  }
].freeze

SCENARIOS = [
  ["01_home", "home", 5.0],
  ["02_characters", "characters", 5.0],
  ["03_poses", "poses", 5.0],
  ["04_editor_lighting", "editor", 8.0],
  ["05_duo_editor", "duo", 8.0],
  ["06_pro_purchase", "paywall", 6.0]
].freeze

def run!(*command)
  puts("$ #{command.join(' ')}")
  success = system(*command)
  raise "Command failed: #{command.join(' ')}" unless success
end

def capture(command)
  stdout, stderr, status = Open3.capture3(*command)
  raise "Command failed: #{command.join(' ')}\n#{stdout}\n#{stderr}" unless status.success?
  stdout
end

def latest_ios_runtime
  runtimes = JSON.parse(capture(["xcrun", "simctl", "list", "runtimes", "--json"])).fetch("runtimes")
  ios = runtimes.select { |runtime| runtime["platform"] == "iOS" && runtime["isAvailable"] }
  raise "No available iOS simulator runtime found" if ios.empty?

  ios.max_by { |runtime| Gem::Version.new(runtime["version"]) }.fetch("identifier")
end

def app_path_for(derived_data)
  app_path = Dir[File.join(derived_data, "Build/Products/Debug-iphonesimulator/PoseReferenceApp.app")].first
  raise "Built app not found under #{derived_data}" unless app_path
  app_path
end

def verify_png(path)
  raise "Missing screenshot #{path}" unless File.file?(path)
  raise "AppleDouble metadata file is not a screenshot: #{path}" if File.basename(path).start_with?("._")
  raise "Empty screenshot #{path}" if File.size(path) < 100_000

  output = capture(["sips", "-g", "pixelWidth", "-g", "pixelHeight", path])
  puts(output)
end

def remove_apple_double_files(*dirs)
  dirs.each do |dir|
    Dir.glob(File.join(dir, "**", "._*")).each { |path| FileUtils.rm_f(path) }
  end
end

def capture_verified_screenshot(udid:, bundle_id:, scenario:, wait_seconds:, output_path:, temp_path:)
  last_error = nil
  3.times do |attempt|
    run!("xcrun", "simctl", "launch", "--terminate-running-process", udid, bundle_id, "--screenshot-scenario", scenario)
    sleep(wait_seconds + attempt * 1.5)
    run!("xcrun", "simctl", "io", udid, "screenshot", temp_path)
    FileUtils.cp(temp_path, output_path)

    begin
      verify_png(output_path)
      return
    rescue StandardError => error
      last_error = error
      warn("Screenshot #{scenario} attempt #{attempt + 1} failed: #{error.message}")
      FileUtils.rm_f(output_path)
      system("xcrun", "simctl", "terminate", udid, bundle_id)
      sleep(1.0)
    end
  end

  raise last_error || "Failed to capture #{scenario}"
end

runtime = latest_ios_runtime
fastlane_locale_dir = File.join(ROOT, "fastlane/screenshots/zh-Hant")
FileUtils.rm_rf(fastlane_locale_dir)
FileUtils.mkdir_p(fastlane_locale_dir)

DEVICES.each do |device|
  screenshot_dir = File.join(ROOT, "Screenshots", device.fetch(:folder))
  derived_data = File.join(ROOT, ".build", "Screenshots", device.fetch(:folder), "DerivedData")
  FileUtils.rm_rf(screenshot_dir)
  FileUtils.rm_rf(derived_data)
  FileUtils.mkdir_p(screenshot_dir)

  udid = capture(["xcrun", "simctl", "create", device.fetch(:name), device.fetch(:type), runtime]).strip
  begin
    run!("xcrun", "simctl", "boot", udid)
    run!("xcrun", "simctl", "bootstatus", udid, "-b")
    run!(
      "xcodebuild",
      "-project", PROJECT,
      "-scheme", SCHEME,
      "-configuration", "Debug",
      "-destination", "platform=iOS Simulator,id=#{udid}",
      "-derivedDataPath", derived_data,
      "-quiet",
      "CODE_SIGNING_ALLOWED=NO",
      "build"
    )
    run!("xcrun", "simctl", "install", udid, app_path_for(derived_data))

    SCENARIOS.each do |name, scenario, wait_seconds|
      output_path = File.join(screenshot_dir, "#{device.fetch(:prefix)}_#{name}.png")
      temp_path = File.join(Dir.tmpdir, "poseframe_#{device.fetch(:prefix)}_#{name}.png")
      capture_verified_screenshot(
        udid: udid,
        bundle_id: BUNDLE_ID,
        scenario: scenario,
        wait_seconds: wait_seconds,
        output_path: output_path,
        temp_path: temp_path
      )
      remove_apple_double_files(screenshot_dir, fastlane_locale_dir)
      FileUtils.cp(output_path, File.join(fastlane_locale_dir, "#{device.fetch(:prefix)}_#{name}.png"))
      remove_apple_double_files(screenshot_dir, fastlane_locale_dir)
      system("xcrun", "simctl", "terminate", udid, BUNDLE_ID)
      sleep(0.6)
    end
  ensure
    system("xcrun", "simctl", "shutdown", udid)
    system("xcrun", "simctl", "delete", udid)
  end
end

remove_apple_double_files(File.join(ROOT, "Screenshots"), fastlane_locale_dir)
remove_apple_double_files(File.dirname(fastlane_locale_dir))
puts("Captured #{DEVICES.size * SCENARIOS.size} App Store screenshots.")
