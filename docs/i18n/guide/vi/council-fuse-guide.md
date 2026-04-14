# Hướng dẫn sử dụng Council Fuse

> Bắt đầu trong 5 phút — thảo luận đa góc nhìn để có câu trả lời tốt hơn

---

## Cài đặt

### Claude Code (khuyến nghị)

```bash
claude plugin add juserai/forge
```

### Cài đặt một dòng phổ quát

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/council-fuse/SKILL.md
```

> **Không phụ thuộc** — Council Fuse không yêu cầu bất kỳ dịch vụ hay API bên ngoài nào. Cài đặt và bắt đầu sử dụng.

---

## Lệnh

| Lệnh | Chức năng | Khi nào sử dụng |
|------|-----------|-----------------|
| `/council-fuse <câu hỏi>` | Chạy một phiên thảo luận hội đồng đầy đủ | Quyết định quan trọng, câu hỏi phức tạp |

---

## Cách hoạt động

Council Fuse đóng gói mô hình LLM Council của Karpathy thành một lệnh duy nhất:

### Giai đoạn 1: Triệu tập

Ba tác tử được khởi chạy **song song**, mỗi tác tử mang một góc nhìn khác nhau:

| Tác tử | Vai trò | Mô hình | Thế mạnh |
|--------|---------|---------|----------|
| Tổng quát | Cân bằng, thực tế | Sonnet | Các phương pháp tốt nhất phổ biến |
| Phản biện | Đối lập, tìm lỗi | Opus | Trường hợp biên, rủi ro, điểm mù |
| Chuyên gia | Chi tiết kỹ thuật sâu | Sonnet | Độ chính xác trong triển khai |

Mỗi tác tử trả lời **độc lập** — họ không thể thấy câu trả lời của nhau.

### Giai đoạn 2: Chấm điểm

Chủ tịch (tác tử chính) ẩn danh hóa tất cả câu trả lời thành Câu trả lời A/B/C, sau đó chấm điểm mỗi câu trên 4 tiêu chí (0-10):

- **Chính xác** — độ chính xác về sự kiện, tính hợp lý logic
- **Đầy đủ** — mức độ bao phủ tất cả các khía cạnh
- **Thực tiễn** — khả năng thực hiện, tính ứng dụng thực tế
- **Rõ ràng** — cấu trúc, tính dễ đọc

### Giai đoạn 3: Tổng hợp

Câu trả lời có điểm cao nhất trở thành khung chính. Những thông tin độc đáo từ các câu trả lời khác được tích hợp. Những phản đối hợp lý của tác tử phản biện được giữ lại làm lưu ý.

---

## Trường hợp sử dụng

### Quyết định kiến trúc

```
/council-fuse Should we use microservices or a monolith for our 10-person team?
```

Tác tử tổng quát cung cấp các đánh giá cân bằng, tác tử phản biện thách thức xu hướng microservices, và chuyên gia trình bày chi tiết các mô hình chuyển đổi. Kết quả tổng hợp đưa ra khuyến nghị có điều kiện.

### Lựa chọn công nghệ

```
/council-fuse Redis vs PostgreSQL for our job queue
```

Ba góc nhìn khác nhau đảm bảo bạn không bỏ sót các vấn đề vận hành (phản biện), chi tiết triển khai (chuyên gia), hoặc lựa chọn mặc định thực dụng (tổng quát).

### Đánh giá mã nguồn

```
/council-fuse Is this error handling pattern correct? <paste code>
```

Nhận trong một lần: xác thực từ góc nhìn phổ biến, phân tích trường hợp biên đối lập, và kiểm tra kỹ thuật chuyên sâu.

---

## Cấu trúc đầu ra

Mỗi phiên thảo luận hội đồng tạo ra:

1. **Bảng điểm** — chấm điểm minh bạch cho cả ba góc nhìn
2. **Phân tích đồng thuận** — điểm đồng ý và điểm bất đồng
3. **Câu trả lời tổng hợp** — câu trả lời tốt nhất đã hợp nhất
4. **Ý kiến thiểu số** — các quan điểm đối lập hợp lý đáng lưu ý

---

## Tùy chỉnh

### Thay đổi góc nhìn

Chỉnh sửa `agents/*.md` để định nghĩa thành viên hội đồng tùy chỉnh. Các bộ ba thay thế:

- Lạc quan / Bi quan / Thực dụng
- Kiến trúc sư / Người triển khai / Người kiểm thử
- Đại diện người dùng / Lập trình viên / Chuyên gia bảo mật

### Thay đổi mô hình

Chỉnh sửa trường `model:` trong mỗi tệp tác tử:

- `model: haiku` — hội đồng tiết kiệm chi phí
- `model: opus` — toàn bộ sức mạnh cho quyết định quan trọng

---

## Nền tảng

| Nền tảng | Cách thành viên hội đồng hoạt động |
|----------|-----------------------------------|
| Claude Code | 3 tác tử độc lập chạy song song |
| OpenClaw | Một tác tử, 3 vòng suy luận độc lập tuần tự |

---

## Câu hỏi thường gặp

**H: Có tốn 3 lần token không?**
Đ: Có, xấp xỉ. Ba câu trả lời độc lập cộng thêm tổng hợp. Hãy sử dụng cho những quyết định xứng đáng với chi phí.

**H: Tôi có thể thêm nhiều thành viên hội đồng hơn không?**
Đ: Framework hỗ trợ điều đó — thêm một tệp `agents/*.md` nữa và cập nhật quy trình trong SKILL.md. Tuy nhiên, 3 là điểm cân bằng tốt nhất giữa chi phí và sự đa dạng.

**H: Nếu một tác tử bị lỗi thì sao?**
Đ: Chủ tịch chấm 0 cho thành viên đó và tổng hợp từ các câu trả lời còn lại. Suy giảm ổn hòa, không bị sập.
