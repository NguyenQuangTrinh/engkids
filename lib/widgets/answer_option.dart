import 'package:flutter/material.dart';

class AnswerOption extends StatelessWidget {
  final String optionText;
  final String optionLetter; // 'A', 'B', 'C', 'D'
  final bool isSelected;
  final VoidCallback onTap; // Hàm callback khi nút được nhấn

  const AnswerOption({
    super.key,
    required this.optionText,
    required this.optionLetter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onTap, // Gọi hàm callback khi nhấn
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Colors.greenAccent[100] // Màu nền khi được chọn
              : Colors.white,         // Màu nền mặc định
          foregroundColor: Colors.black87, // Màu chữ
          padding: EdgeInsets.symmetric(vertical: 18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
            side: BorderSide(
              color: isSelected ? Colors.green : Colors.grey.shade400, // Màu viền
              width: 2.5, // Độ dày viền
            ),
          ),
          elevation: isSelected ? 2 : 4, // Đổ bóng
        ),
        child: Row( // Sử dụng Row để căn chỉnh chữ cái và nội dung
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 20), // Khoảng cách lề trái
            // Hiển thị chữ cái trong vòng tròn nhỏ (ví dụ)
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected ? Colors.green : Colors.blueGrey[300],
              child: Text(
                optionLetter,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 15), // Khoảng cách giữa chữ cái và nội dung
            // Sử dụng Expanded để nội dung tự động giãn ra
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
                overflow: TextOverflow.ellipsis, // Tránh tràn chữ nếu quá dài
              ),
            ),
            SizedBox(width: 20), // Khoảng cách lề phải
          ],
        ),
      ),
    );
  }
}