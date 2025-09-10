// lib/widgets/vocabulary/import_set_dialog.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vocabulary_providers.dart';
import '../../service/firebase_vocabulary_service.dart'; // <<< THAY ĐỔI SERVICE

class ImportSetDialogContent extends ConsumerStatefulWidget {
  const ImportSetDialogContent({super.key});

  @override
  ConsumerState<ImportSetDialogContent> createState() =>
      _ImportSetDialogContentState();
}

class _ImportSetDialogContentState
    extends ConsumerState<ImportSetDialogContent> {
  late final TextEditingController _setNameController;
  late final TextEditingController _setDescriptionController;
  bool _isImporting = false;
  String? _selectedJsonContent;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _setNameController = TextEditingController();
    _setDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _setNameController.dispose();
    _setDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // Yêu cầu file_picker đọc cả nội dung file
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      try {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        setState(() {
          _selectedJsonContent = content;
          _selectedFileName = result.files.single.name;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi đọc file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    final setName = _setNameController.text.trim();
    final setDescription = _setDescriptionController.text.trim();

    setState(() {
      _isImporting = true;
    });

    try {
      // Gọi hàm `importVocabularyFromJsonString` và truyền nội dung JSON
      final success = await FirebaseVocabularyService.instance
          .importVocabularyFromJsonString(
            _selectedJsonContent!,
            setName,
            setDescription: setDescription.isNotEmpty ? setDescription : null,
          );

      if (!mounted) return;

      if (success) {
        ref.invalidate(vocabularySetsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nhập bộ từ '$setName' lên Firebase thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception("Không thêm được từ nào.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lỗi: ${e.toString().replaceFirst("Exception: ", "")}",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập Bộ Từ Vựng Mới từ JSON'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: _setNameController,
              decoration: const InputDecoration(
                hintText: "Tên chủ đề (bắt buộc)",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _setDescriptionController,
              decoration: const InputDecoration(hintText: "Mô tả (tùy chọn)"),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFileName == null
                        ? 'Chưa chọn file JSON'
                        : 'File: $_selectedFileName',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: _pickJsonFile,
                  tooltip: "Chọn file JSON",
                ),
              ],
            ),
            if (_isImporting) ...[
              const SizedBox(height: 15),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed:
              (_setNameController.text.trim().isEmpty ||
                      _selectedJsonContent == null ||
                      _isImporting)
                  ? null
                  : _handleImport,
          child: const Text('Nhập & Lưu'),
        ),
      ],
    );
  }
}
