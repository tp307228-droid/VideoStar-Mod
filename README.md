# VideoStar-Mod — FallVds Tool 🌟

> Mod IPA: VideoStar 15.2.3 Pro + FallVds Tool inject

[![Build](https://github.com/tp307228-droid/VideoStar-Mod/actions/workflows/build.yml/badge.svg)](https://github.com/tp307228-droid/VideoStar-Mod/actions)
[![Release](https://img.shields.io/github/v/release/tp307228-droid/VideoStar-Mod?label=Download)](https://github.com/tp307228-droid/VideoStar-Mod/releases/latest)

---

## Tính Năng

| Tính Năng | Mô Tả |
|-----------|--------|
| 🖼️ **Chạm Thay Media** | Chọn 1 ảnh → tự động thay ALL lớp ảnh & video trong dự án |
| 📷 **Nhập QR Hàng Loạt** | Chọn đoạn từ→đến, chọn loại QR, chọn ảnh có số đánh dấu |
| 🛡️ **Hide of Stream** | Ẩn tool khỏi quay màn hình, chụp màn hình & live stream |
| 🔑 **Bản Quyền** | Key system, UUID thiết bị, đăng xuất |
| ⭐ **Nút Nổi** | Kéo được, snap vào cạnh, hiệu ứng pulse |
| 🎉 **Pro Popup** | Chào mừng + link Discord |

---

## Cách Dùng

### 1. Tải IPA
👉 [**Releases**](https://github.com/tp307228-droid/VideoStar-Mod/releases/latest) → Tải `VideoStar-Mod-FallVds.ipa`

### 2. Cài đặt
Chọn 1 trong các cách:
- **TrollStore** (không cần máy Mac, không cần revoke)
- **AltStore** (cần Apple ID)
- **Sideloadly** (cần máy Mac/PC)

### 3. Kích hoạt key (Beta)
Mở VideoStar → nhấn ⭐ nổi → tab **Bản Quyền** → nhập key:
```
MinhTienVds
```

---

## Cấu Trúc Source

```
mod/
├── Tweak.x                  # Entry point, hooks UIWindow + UIScreen
├── Makefile                 # Theos build config
├── control                  # Package metadata
├── FallVdsTool/
│   ├── Theme.h              # Design system (colors, gradients)
│   ├── SVGIcons.h           # Pure UIBezierPath SVG icons
│   ├── FloatingButton.{h,m} # Floating button, draggable, snap
│   ├── HideStream.{h,m}     # Ẩn tool khỏi screen capture
│   ├── LicenseManager.{h,m} # Key system
│   ├── LicenseVC.{h,m}      # Tab Bản Quyền UI
│   ├── MediaReplacerVC.{h,m}# Chạm Thay Media UI
│   ├── QRImporterVC.{h,m}   # Nhập QR Hàng Loạt UI
│   └── FallVdsToolUI.{h,m}  # Main menu, overlay window
└── .github/workflows/
    └── build.yml            # GitHub Actions: build dylib + inject IPA
```

---

## Build Thủ Công

> Cần Mac + Xcode + Theos

```bash
git clone https://github.com/tp307228-droid/VideoStar-Mod
cd VideoStar-Mod/mod
export THEOS=~/theos
make package FINALPACKAGE=1
```

---

## Discord

[![Discord](https://img.shields.io/discord/swaggang?label=discord.gg%2Fswaggang&logo=discord&color=5865F2)](https://discord.gg/swaggang)

---

> Made with ❤️ by **FallVds Team**
