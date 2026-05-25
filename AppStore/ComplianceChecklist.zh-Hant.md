# App Store 上架檢核清單

更新日期：2026-05-25

## 已完成並已驗證

- Bundle ID：`com.yushang.poseframe3d`。
- Team ID：`7H7ZUG2WX8`，Team / 聯絡人：Yu Shiung Jiang。
- App 顯示名稱：PoseFrame Studio。
- Privacy Policy URL：`https://kingboss568.github.io/poseframe-3d-ios/privacy.html`，已在 GitHub repo 的 `docs/privacy.html` 並已 push。
- Support URL：`https://kingboss568.github.io/poseframe-3d-ios/support.html`，已在 GitHub repo 的 `docs/support.html` 並已 push。
- `PrivacyInfo.xcprivacy` 已通過 `plutil -lint`，宣告不追蹤、不蒐集資料。
- `NSPhotoLibraryAddUsageDescription` 已提供用途：只在使用者主動儲存匯出圖時新增照片。
- StoreKit 2 IAP Product ID：`com.yushang.poseframe3d.pro`，類型為 non-consumable 一次性解鎖。
- 審查備註、App Store listing、IAP JSON、metadata、review information 已放在 `AppStore/` 與 `fastlane/metadata/zh-Hant/`。
- iPhone 6.9 吋截圖 6 張已產出：`Screenshots/iphone69/` 與 `fastlane/screenshots/zh-Hant/`。
- iPad 13 吋截圖 6 張已產出：`Screenshots/ipad13/` 與 `fastlane/screenshots/zh-Hant/`。
- 截圖腳本已加入 PNG 驗證、空白圖重試與 `._*` 隱藏檔清理。
- App Store provisioning profile 已建立並安裝：`PoseFrame Studio App Store`。
- fastlane `ios verify` 通過。
- fastlane `ios build_ipa` 已成功輸出簽名 IPA：`Build/PoseFrameStudio.ipa`，build number `4`。
- IPA 內含 `PrivacyInfo.xcprivacy`，簽名為 `Apple Distribution: Yu Shiung Jiang (7H7ZUG2WX8)`。
- iPad 已設定支援四方向，避免「非全螢幕 iPad App 必須支援所有方向」警告。

## 尚未完成 / 送審阻塞

- App Store Connect app record 尚未建立。ASC API key 可建立 Bundle ID 與 provisioning profile，但 Apple API 回覆 `apps` 不允許 `CREATE`，因此無法用此 API key 建立 app record。
- 因 app record 尚不存在，IAP 商品尚無法在 App Store Connect app 底下建立、設定價格或附加到版本。
- 因 app record 尚不存在，metadata、screenshots、IPA 尚未能上傳到 App Store Connect，也尚未送出審查。
- Comet UI 流程需要 Mac 解鎖後才能操作；目前本機畫面停在鎖定畫面，無法安全操作 ASC 表單。

## 下一步

1. 解鎖 Mac，使用 Comet 開啟 App Store Connect。
2. 在 App Store Connect 手動建立 app record：
   - Name：PoseFrame Studio
   - Bundle ID：`com.yushang.poseframe3d`
   - SKU：`POSEFRAME3D-2026`
   - Primary locale：繁體中文
3. 建立 non-consumable IAP：`com.yushang.poseframe3d.pro`，填入名稱、描述、價格，並附加到 app version。
4. 回到本 repo 執行 `fastlane ios upload` 上傳 metadata、screenshots、IPA。
5. App Store Connect 確認 build processing 完成、IAP 可提交後，再執行 `fastlane ios release` 或在 Comet 中送出審查。

## 審查風險提醒

- 不可在送審資料中宣稱沒有 App 內購買；本 app 目前有 non-consumable IAP。
- 不可把 build 成功當作送審就緒；必須等 ASC app record、IAP、價格、build processing、Privacy / Support URLs 都完成。
- 3D 角色已從木偶式關節假人改為較連續的人體/服裝造型，但若目標是照片級擬真，仍建議下一版導入正式授權的 rigged human 3D asset。
