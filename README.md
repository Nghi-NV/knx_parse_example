# KNX Parse Example

Trang web dùng thư viện [knx_parse](../knx_parse) để parse file `.knxproj` sang JSON ngay trên trình duyệt (không cần server).

## Cách dùng

1. **Build JS** (chỉ cần làm một lần hoặc sau khi sửa code):

   ```bash
   dart pub get
   dart compile js web/main.dart -o web/main.dart.js
   ```

2. **Chạy trang** — cần serve qua HTTP (mở file trực tiếp có thể bị giới hạn):

   ```bash
   # Cách 1: Dart
   dart run webdev serve web

   # Cách 2: Python 3
   python3 -m http.server 8080 --directory web

   # Cách 3: npx
   npx serve web -p 8080
   ```

3. Mở trình duyệt: `http://localhost:8080` (hoặc cổng bạn chọn).

4. Chọn file `.knxproj`, nhập mật khẩu nếu project mã hóa, bấm **Parse sang JSON**. Có thể tải file JSON về bằng nút **Tải file JSON**.

## Cấu trúc

- `web/index.html` — giao diện
- `web/main.dart` — logic: đọc file, gọi `KnxProjectParser().parseBytes(bytes, password: pwd)`, hiển thị và tải JSON
- `web/styles.css` — giao diện tối, đơn giản

Phụ thuộc: [knx_parser](https://pub.dev/packages/knx_parser) từ pub.dev.

## GitHub Pages

Workflow deploy nằm trong **`.github/workflows/deploy-pages.yml`** (trong thư mục này).

1. **Bật GitHub Pages** (một lần):
   - Vào repo → **Settings** → **Pages**
   - **Build and deployment** → **Source**: chọn **GitHub Actions**

2. **Repo riêng (gốc là knx_parse_example)**: Nếu đây là repo độc lập, workflow trên sẽ chạy khi push lên `main`/`master`. Trang: `https://<username>.github.io/<repo>/`

3. **Nằm trong repo khác (monorepo)**: GitHub chỉ chạy workflow từ thư mục gốc repo. Cần copy `.github/workflows/deploy-pages.yml` vào `<repo-gốc>/.github/workflows/` và sửa:
   - `run: dart pub get` → `run: cd knx_parse_example && dart pub get`
   - `run: dart compile js ...` → `run: cd knx_parse_example && dart compile js web/main.dart -o web/main.dart.js`
   - `path: web` → `path: knx_parse_example/web`

4. **Deploy thủ công**: Vào **Actions** → **Deploy to GitHub Pages** → **Run workflow**.
