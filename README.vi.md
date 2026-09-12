<p align="center">
  <img src="assets/icon/icon.png" alt="Icon DualCal" width="120" />
</p>

<h1 align="center">DualCal</h1>

<p align="center">
  Lịch song hành dương lịch - âm lịch — ghi chú, nhắc nhở, ngày lễ, và giao diện neumorphic mềm mại.
</p>

<p align="center">
  <a href="https://fralcy.github.io/DualCal/">🔗 Bản demo trực tuyến (web)</a>
  ·
  <a href="README.md">English</a>
</p>

---

## Tính năng

- **Lịch song hành** — mỗi ngày hiển thị cả ngày dương lịch và âm lịch, tính toán bằng thuật toán Hồ Ngọc Đức viết lại thuần Dart (không dùng bảng tra cứu, không phụ thuộc package âm lịch của bên thứ ba).
- **Ghi chú & sự kiện** — gắn ghi chú vào ngày dương hoặc ngày âm, một lần hoặc lặp lại hàng năm (sinh nhật neo theo âm lịch sẽ lặp lại đúng theo âm lịch mỗi năm, không phải một ngày dương lịch cố định).
- **Nhắc nhở** — chọn tuỳ ý số mốc "ngày trước" cùng giờ nhắc cụ thể; thông báo hệ điều hành thật trên mobile/desktop, danh sách "sắp tới" hiển thị trong app trên web (trình duyệt không thể đảm bảo bắn thông báo khi tab đã đóng).
- **Ngày lễ** — ngày nghỉ lễ Việt Nam (Tết và các ngày liên quan, Giỗ Tổ Hùng Vương, Quốc khánh, …) cùng các dịp lễ Việt Nam/quốc tế khác, có sẵn và hiển thị trực tiếp trên lưới lịch.
- **Việt / Anh** — giao diện đa ngôn ngữ đầy đủ, chuyển đổi trong phần Cài đặt.
- **Giao diện Neumorphism** — 5 bộ màu soft-UI dựng sẵn (kể cả 1 bản tối), áp dụng nhất quán trên lịch, các modal và nút bấm.
- **Sao lưu** — xuất toàn bộ ghi chú/cài đặt ra file JSON và nhập lại sau này, chọn gộp hoặc thay thế dữ liệu hiện có.
- **Responsive** — một codebase thích ứng giữa layout mobile (lưới toàn màn hình + bottom sheet) và layout desktop/web (lưới + panel chi tiết cố định), có phím tắt (mũi tên, Page Up/Down, Home/T, Enter, Escape) và vuốt để đổi tháng trên cảm ứng.

## Công nghệ sử dụng

Flutter (Android/iOS/Windows/macOS/Linux/Web từ 1 codebase), `provider` cho state management, `hive` để lưu trữ local (offline-first, không cần backend), `flutter_local_notifications` + `timezone` cho nhắc nhở, `intl`/`flutter_localizations` cho đa ngôn ngữ, `file_picker` cho xuất/nhập backup.

## Bắt đầu

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # sinh Hive adapter (lib/**/*.g.dart)
flutter gen-l10n                                           # sinh AppLocalizations (hoặc tự động khi run/build)
flutter run
```

Chạy test bằng `flutter test`, kiểm tra tĩnh bằng `flutter analyze`.

### Build cho web

```bash
flutter build web --release --base-href /DualCal/
```

Mỗi lần push lên `main` sẽ tự động build lại và deploy lên GitHub Pages qua `.github/workflows/deploy-pages.yml`.

### Sinh lại icon app

Ảnh gốc của icon nằm ở `assets/icon/icon.png`. Sau khi thay ảnh mới, chạy lệnh sau để sinh lại icon cho mọi nền tảng:

```bash
dart run flutter_launcher_icons
```

## Hạn chế đã biết

- Việc gửi thông báo trên thiết bị thật (qua `flutter_local_notifications`) mới chỉ được unit test với fake service, chưa xác minh trên điện thoại/máy Android hoặc iOS thật.
- Chưa cấu hình ký ứng dụng (keystore Android, provisioning iOS) — dự án hiện nhắm tới bản web và cài đặt local/dev.
- Chưa có bước kiểm tra tự động trên CI (workflow GitHub Actions hiện chỉ build và deploy; `flutter test`/`flutter analyze` được chạy thủ công trước mỗi commit).
