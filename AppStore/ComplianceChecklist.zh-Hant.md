# App Store 上架檢核清單

更新日期：2026-05-30

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
- fastlane `ios build_ipa` 已成功輸出簽名 IPA：`Build/PoseFrameStudio.ipa`，build number `6`。
- IPA 內含 `PrivacyInfo.xcprivacy`，簽名為 `Apple Distribution: Yu Shiung Jiang (7H7ZUG2WX8)`。
- ASC API 已確認 build `6` 狀態為 `VALID` / `APP_STORE_ELIGIBLE`，並已綁定到 iOS 版本 `1.0`。
- fastlane `ios metadata` 已成功上傳 metadata 與 iPhone 6.9 / iPad 13 截圖，precheck 無問題。
- App Store Connect app record 已建立，Apple ID：`6774984271`，SKU：`com.yushang.poseframe3d`。
- IAP 商品已由 ASC API 建立，Product ID：`com.yushang.poseframe3d.pro`，ASC IAP ID：`6774986385`，狀態 `READY_TO_SUBMIT`。
- IAP 已設定 USA base territory 價格 `USD 4.99`，Apple 已自動產生其他地區價格。
- IAP review note、availability 與 App Review screenshot 已上傳；付款頁截圖檔名：`iphone69_06_pro_purchase.png`。
- iPad 已設定支援四方向，避免「非全螢幕 iPad App 必須支援所有方向」警告。

## 尚未完成 / 送審阻塞

- 尚未按下最後「送出審查」。依上架技能規範，最後 submit 需要使用者明確確認。
- 送審前仍建議在 Comet 最後目視確認年齡分級、類別與 IAP 是否顯示在版本頁。

## 下一步

1. 使用 Comet 打開 App Store Connect 版本頁，確認 build `6`、IAP `PoseFrame Studio Pro`、年齡分級、類別與審查資訊。
2. 使用者明確確認後，再執行 `fastlane ios release` 或在 Comet 中送出審查。

## 審查風險提醒

- 不可在送審資料中宣稱沒有 App 內購買；本 app 目前有 non-consumable IAP。
- 不可把 build 成功當作送審就緒；必須等 ASC app record、IAP、價格、build processing、Privacy / Support URLs 都完成。
- 3D 角色已從木偶式關節假人改為較連續的人體/服裝造型，但若目標是照片級擬真，仍建議下一版導入正式授權的 rigged human 3D asset。
