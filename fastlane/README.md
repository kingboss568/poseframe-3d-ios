fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios verify

```sh
[bundle exec] fastlane ios verify
```

Run local App Store readiness checks.

### ios ensure_asc_records

```sh
[bundle exec] fastlane ios ensure_asc_records
```

Create or verify App Store Connect app and IAP records through the App Store Connect API.

### ios ensure_profile

```sh
[bundle exec] fastlane ios ensure_profile
```

Create and install the App Store provisioning profile used to export the IPA.

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture iPhone 6.9-inch and iPad 13-inch App Store screenshots.

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata, privacy/support URLs, review info, and screenshots without binary.

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build a signed App Store IPA.

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Build and upload metadata, screenshots, and IPA; do not submit for review.

### ios upload_existing_ipa

```sh
[bundle exec] fastlane ios upload_existing_ipa
```

Upload the existing IPA, metadata, and screenshots without rebuilding.

### ios upload_ipa_only

```sh
[bundle exec] fastlane ios upload_ipa_only
```

Upload only the existing IPA, leaving metadata and screenshots untouched.

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit the already uploaded App Store version for review without rebuilding or reuploading assets.

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload all App Store material and submit the app version for review.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
