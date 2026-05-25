# PoseFrame 3D iPhone App

PoseFrame Studio 是一個 SwiftUI + SceneKit 製作的 iOS 姿勢參考工具。它包含首頁、角色庫、姿勢模板、3D Pose 編輯器、匯出流程、App Icon、Privacy Manifest、上架文案、IAP 草稿、GitHub Pages 隱私/支援頁與 fastlane 上架流程。

## 打開方式

1. 用 Xcode 26 或更新版本開啟 `PoseReferenceApp.xcodeproj`。
2. 選擇 iPhone 或 iOS Simulator。
3. 執行 `PoseReferenceApp` scheme。

## 已實作

- 首頁：最近專案、快速新建單人/雙人、熱門姿勢、即時 3D 預覽。
- 角色庫：搜尋、性別/風格篩選、收藏、主角/配角套用。
- 姿勢模板：分類、搜尋、收藏、單人/雙人模板套用。
- Pose 編輯器：SceneKit 程序化 3D 人體比例模型、角色切換、鏡像、格線、相機預設、焦距、距離、燈光、陰影、道具。
- 匯出：SceneKit 離線渲染預覽、iOS 分享面板、照片圖庫儲存。
- Pro 解鎖：StoreKit 2 non-consumable IAP，Product ID `com.yushang.poseframe3d.pro`。
- 上架準備：App Icon、`PrivacyInfo.xcprivacy`、照片新增權限說明、App Store Listing、Review Notes、Privacy Policy、Support、Compliance Checklist、fastlane metadata/screenshots/IPA lanes。

## 自我檢核指令

```bash
xcodegen generate
xcodebuild -project PoseReferenceApp.xcodeproj -scheme PoseReferenceApp -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
ruby Scripts/verify_submission_readiness.rb
fastlane ios screenshots
fastlane ios upload
```

`fastlane ios release` 會嘗試建立/確認 App Store Connect 記錄、截圖、建置 IPA、上傳 metadata/screenshots/binary 並送審。送審前必須確認 IAP 已設定價格並附加到 app version。

## 上架前仍需補齊

- App Store Connect 內的 IAP 價格表與 app version 附加狀態。
- GitHub Pages 隱私與支援頁需 push 並確認可公開開啟。
- fastlane 上傳後需確認最新 build 在 App Store Connect 顯示且處理完成。

## 後續接正式模型

目前沒有正式 `.usdz` 或 `.reality` 角色資產，因此先用 SceneKit 生成可擺姿的程序化人體比例模型。等正式角色資產準備好後，可把 `SceneKitPoseView` 的程序化模型替換成模型載入與骨架控制層。
