# App Store 上架檢核清單

本清單依 Apple 官方文件整理，完成日期：2026-05-12。

## 已完成

- 使用 Xcode 26.5 / iOS SDK 26.5 建置，符合 2026-04-28 起 App Store Connect 新上傳 App 必須使用 Xcode 26 或更新 SDK 的要求。
- App target 可成功 build，XcodeBuildMCP build/run 成功。
- 單元測試已在 iOS 26.4 Simulator 執行，3 passed / 0 failed。
- App Icon 已產生 iPhone 必要尺寸與 1024x1024 marketing icon，無透明背景、無文字。
- `PrivacyInfo.xcprivacy` 已宣告不追蹤、不蒐集資料。
- `NSPhotoLibraryAddUsageDescription` 已提供明確用途：只在使用者儲存匯出圖時新增照片。
- App 無登入、無 IAP、無廣告、無第三方 SDK、無後端、無 UGC。
- 上架文案、審查備註、隱私政策草稿已放在 `AppStore/`。

## App Store Connect 送審前需人工完成

- 建立正式 App ID / Bundle ID：`com.poseframe3d.referenceapp`，並設定 Team 簽章。
- 填入公開可訪問的 Privacy Policy URL。Apple App Store Connect 要求所有 App 都必須提供 Privacy Policy URL。
- 填入 Support URL，並提供可聯絡方式。
- 在 App Privacy answers 選擇不蒐集資料；若未來加入分析、帳號、雲端或第三方 SDK，必須重新申報。
- 提供 iPhone 實機或模擬器截圖，截圖需展示真實功能畫面。
- 年齡分級建議填 4+；若未來加入成人、暴力、UGC 或外部內容，需重新評估。
- 提交前用 Release configuration 在真機或目標 iPhone 模擬器完整操作一次。

## Apple 官方依據

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：提交前需測試 crashes/bugs、metadata 完整準確、提供完整審查存取、說明非顯而易見功能。
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)：App Store Connect 需要提供隱私作法；只在裝置端處理且不傳出裝置的資料不屬於 Apple 定義的 collected data。
- [App privacy reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/)：Privacy Policy URL 是所有 App 必填。
- [Human Interface Guidelines: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)：App icon 應清楚傳達 App 用途並在系統中易於辨識。
- [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)：2026-04-28 起新上傳 App 必須以 Xcode 26 或更新版本和對應 SDK 建置。
