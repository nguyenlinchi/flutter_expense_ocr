# Expense Tracker AI 

Ứng dụng quản lý chi tiêu cá nhân được xây dựng bằng **Flutter**, hỗ trợ lưu trữ dữ liệu ngoại tuyến, quét hóa đơn bằng OCR và phân tích thói quen chi tiêu bằng Gemini AI.

## Tác giả

**Nguyễn Thị Linh Chi_Mã sv: 23IT.B018 Role:FullStack**

##  Giới thiệu

Expense Tracker AI giúp người dùng theo dõi các khoản chi tiêu hằng ngày, quản lý ngân sách và hiểu rõ hơn về tình hình tài chính cá nhân. Ứng dụng ưu tiên lưu trữ dữ liệu trên thiết bị, đồng thời tích hợp AI để đưa ra nhận xét và đề xuất tiết kiệm dựa trên dữ liệu chi tiêu.

##  Tính năng chính

- **Dashboard:** Tổng quan tình hình chi tiêu và ngân sách.
- **Quản lý giao dịch:** Thêm, xem, chỉnh sửa và xóa các khoản chi tiêu.
- **Quét hóa đơn bằng OCR:** Chụp ảnh hoặc chọn ảnh hóa đơn để trích xuất văn bản và nhận diện thông tin chi tiêu.
- **Lưu trữ ngoại tuyến:** Sử dụng SQLite để lưu dữ liệu giao dịch trên thiết bị.
- **Báo cáo và biểu đồ:** Theo dõi tổng chi tiêu và phân tích theo danh mục.
- **Quản lý ngân sách:** Thiết lập thu nhập, giới hạn chi tiêu tháng và mục tiêu tiết kiệm.
- **Phân tích chi tiêu bằng Gemini AI:** Tạo nhận xét về tình hình tài chính và đề xuất cách tiết kiệm.
- **Cài đặt ứng dụng:** Quản lý tùy chọn AI và các thiết lập tài chính.

##  Công nghệ sử dụng

| Công nghệ | Mục đích |
|---|---|
| Flutter / Dart | Xây dựng ứng dụng đa nền tảng |
| SQLite / sqflite | Lưu trữ giao dịch cục bộ |
| Google ML Kit Text Recognition | Nhận diện văn bản từ ảnh hóa đơn |
| Image Picker / Camera | Chụp hoặc chọn ảnh |
| Image Cropper | Cắt ảnh hóa đơn |
| Flutter Riverpod | Quản lý trạng thái và dữ liệu |
| Node.js / Express | Xây dựng backend cho chức năng AI |
| Google Gemini API | Phân tích chi tiêu và đề xuất tiết kiệm |
| HTTP | Giao tiếp giữa Flutter và backend |
| Shared Preferences | Lưu các thiết lập ứng dụng |

##  Kiến trúc hệ thống

```text
┌─────────────────────────────┐
│      Flutter Application    │
│                             │
│ Dashboard / Transactions    │
│ Reports / Settings          │
│ Receipt Scanner / OCR       │
└──────────────┬──────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌──────────────┐  ┌────────────────┐
│ SQLite Local │  │ Node.js Backend │
│ Database     │  │ Express API     │
└──────────────┘  └───────┬────────┘
                          │
                          ▼
                  ┌────────────────┐
                  │ Gemini API     │
                  │ AI Analysis    │
                  └────────────────┘
```

**Luồng phân tích AI:**

1. Flutter đọc dữ liệu giao dịch của tháng hiện tại.
2. Ứng dụng tổng hợp tổng chi tiêu, các danh mục và thiết lập ngân sách.
3. Flutter gửi dữ liệu tổng hợp đến backend Node.js.
4. Backend gọi Gemini API để phân tích.
5. Kết quả được trả về ứng dụng để hiển thị nhận xét và đề xuất tiết kiệm.

API key được cấu hình ở backend, không nhúng trực tiếp vào mã nguồn Flutter.

##  Yêu cầu môi trường

- Flutter SDK và Dart SDK.
- Android Studio hoặc Android SDK.
- Android Emulator hoặc thiết bị Android thật.
- Node.js phiên bản 18 trở lên.
- Google Gemini API key.
- Git.

##  Cài đặt và chạy ứng dụng

### 1. Clone repository

```bash
git clone https://github.com/nguyenlinchi/flutter_expense_ocr
cd flutter_expense_ocr
```

### 2. Cài đặt dependencies Flutter

```bash
flutter pub get
```

Kiểm tra môi trường:

```bash
flutter doctor
flutter devices
```

### 3. Khởi động Android Emulator

Mở máy ảo Android từ Android Studio hoặc chạy:

```bash
flutter emulators
flutter emulators --launch Medium_Phone_API_35
flutter devices
```

Tên emulator có thể khác tùy theo cấu hình trên máy tính.

### 4. Chạy ứng dụng Flutter

Nếu chỉ sử dụng các chức năng cục bộ:

```bash
flutter run -d emulator-5554
```

Nếu sử dụng chức năng phân tích Gemini, hãy cấu hình và khởi động backend trước theo hướng dẫn bên dưới, sau đó chạy:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` là địa chỉ đặc biệt để Android Emulator truy cập máy tính đang chạy backend tại cổng `3000`.

##  Cài đặt backend Gemini AI

Backend được tổ chức trong thư mục riêng `expense-ai-backend`.

### 1. Cài đặt packages

```bash
cd expense-ai-backend
npm install
```

Các dependencies chính gồm:

- `express`
- `dotenv`
- `helmet`
- `express-rate-limit`

### 2. Cấu hình biến môi trường

Tạo file `.env` trong thư mục backend:

```dotenv
PORT=3000
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
GEMINI_MODEL=YOUR_AVAILABLE_GEMINI_MODEL
```

Lấy API key tại [Google AI Studio](https://aistudio.google.com/apikey).

Thay `YOUR_GEMINI_API_KEY` bằng API key của bạn và `YOUR_AVAILABLE_GEMINI_MODEL` bằng model Gemini hiện được hỗ trợ cho API key đó.

**Lưu ý bảo mật:** Không commit file `.env` hoặc công khai API key trên GitHub.

### 3. Chạy backend

```bash
npm run dev
```

Nếu backend khởi động thành công, terminal sẽ hiển thị thông báo dịch vụ đang chạy tại cổng `3000`.

### 4. Kiểm tra backend

Mở trình duyệt và truy cập:

```text
http://localhost:3000/api/health
```

Kết quả mong đợi:

```json
{
  "status": "ok",
  "service": "expense-ai-backend"
}
```

Sau khi backend hoạt động, mở ứng dụng Flutter trên emulator và thử tính năng **Phân tích chi tiêu bằng AI**.

##  Bảo mật và quyền riêng tư

- Giao dịch được lưu trữ cục bộ bằng SQLite.
- Ảnh hóa đơn được xử lý theo cơ chế lưu trữ của ứng dụng.
- Chỉ gửi dữ liệu tổng hợp cần thiết đến backend khi thực hiện phân tích AI.
- Gemini API key được lưu trong biến môi trường của backend.
- Không đưa `.env`, API key hoặc thông tin cá nhân vào repository công khai.

> Khi triển khai backend lên Internet, cần sử dụng HTTPS, bổ sung xác thực và giới hạn yêu cầu phù hợp. Cấu hình HTTP với `10.0.2.2` chỉ dành cho môi trường phát triển cục bộ.

##  Kiểm thử

Chạy các lệnh sau tại thư mục Flutter:

```bash
dart format lib
flutter analyze
flutter test
```

Các chức năng nên được kiểm tra:

- Thêm, sửa và xóa giao dịch.
- Dữ liệu còn tồn tại sau khi đóng và mở lại ứng dụng.
- OCR nhận diện thông tin từ ảnh hóa đơn.
- Tổng chi tiêu và biểu đồ khớp với dữ liệu giao dịch.
- Thiết lập ngân sách được lưu chính xác.
- Backend trả về trạng thái hoạt động.
- Gemini trả về kết quả phân tích hoặc thông báo lỗi phù hợp.

##  Cấu trúc dự án tham khảo

flutter_expense_ocr_project/
├──
    expense_ocr_flutter/
    ├── lib/
    │   ├── database/
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── services/
    │   └── main.dart
    ├── android/
    ├── test/
    ├── pubspec.yaml
    ├── analysis_options.yaml

    expense-ai-backend/
    ├── src/
    │   ├── server.js
    │   └── gemini_service.js
    ├── .env
    ├── .env.example
    ├── .gitignore
    └── package.json
├──README.md

Cấu trúc trên mang tính tham khảo; tên thư mục thực tế có thể thay đổi theo phiên bản dự án.

##  Hướng phát triển

- Hoàn thiện giao diện dashboard và trải nghiệm người dùng.
- Cải thiện độ chính xác khi trích xuất dữ liệu hóa đơn.
- Bổ sung xuất báo cáo và sao lưu dữ liệu.
- Bổ sung ngân sách theo từng danh mục.
- Cải thiện khả năng phân tích xu hướng chi tiêu.
- Tăng cường bảo mật và triển khai backend trên môi trường HTTPS.


---

*Expense Tracker AI — Theo dõi chi tiêu, quản lý ngân sách và xây dựng thói quen tài chính tốt hơn.*
