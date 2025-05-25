import 'dart:io'; // Cho File
import 'package:engkids/screens/vocabulary/vocabulary_set_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer' as developer;
import '../../../models/vocabulary_set_model.dart';
import '../../../widgets/vocabulary/vocabulary_set_list_item.dart';
import '../../models/flashcard_item_model.dart';
import '../../service/vocabulary_database_service.dart';
import 'flashcard_screen.dart';
// import 'vocabulary_set_detail_screen.dart'; // Sẽ tạo sau

class VocabularySetManagementScreen extends StatefulWidget {
  const VocabularySetManagementScreen({super.key});

  @override
  VocabularySetManagementScreenState createState() => VocabularySetManagementScreenState();
}

class VocabularySetManagementScreenState extends State<VocabularySetManagementScreen> {
  List<VocabularySetModel> _vocabularySets = [];
  bool _isLoading = true;
  String? _error;
  final VocabularyDatabaseService _vocabDbService = VocabularyDatabaseService.instance;
  static const String _logName = 'com.engkids.vocabsetmanagement';

  final _setNameController = TextEditingController();
  final _setDescriptionController = TextEditingController(); // Tùy chọn
  File? _selectedJsonFile;

  @override
  void initState() {
    super.initState();
    _loadVocabularySets();
  }

  @override
  void dispose() {
    _setNameController.dispose();
    _setDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularySets() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // Giả sử DatabaseService có hàm getAllVocabularySetsWithWordCount
      // Hoặc bạn cần query riêng word count
      final sets = await _vocabDbService.getAllVocabularySets(); // Cần đảm bảo hàm này trả về wordCount
      if (mounted) {
        setState(() { _vocabularySets = sets; _isLoading = false; });
      }
    } catch (e, s) {
      developer.log("Lỗi tải bộ từ vựng", name: _logName, error: e, stackTrace: s);
      if (mounted) {
        setState(() { _error = "Không thể tải bộ từ."; _isLoading = false; });
      }
    }
  }

  Future<void> _pickJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedJsonFile = File(result.files.single.path!);
      });
      developer.log("Đã chọn file JSON: ${_selectedJsonFile?.path}", name: _logName);
    } else {
      developer.log("Hủy chọn file JSON.", name: _logName);
    }
  }

  Future<void> _showImportSetDialog() async {
    _setNameController.clear();
    _setDescriptionController.clear();
    setState(() { _selectedJsonFile = null; }); // Reset file đã chọn

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải nhấn nút
      builder: (BuildContext dialogContext) {
        // Dùng StatefulBuilder để dialog có thể cập nhật UI (ví dụ tên file đã chọn)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nhập Bộ Từ Vựng Mới từ JSON'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: _setNameController,
                      decoration: InputDecoration(hintText: "Tên chủ đề/bộ từ (bắt buộc)"),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _setDescriptionController,
                      decoration: InputDecoration(hintText: "Mô tả (tùy chọn)"),
                      maxLines: 2,
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedJsonFile == null
                                ? 'Chưa chọn file JSON'
                                : 'File: ${_selectedJsonFile!.path.split('/').last}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file_rounded),
                          onPressed: () async {
                            await _pickJsonFile();
                            setDialogState(() {}); // Cập nhật UI của Dialog
                          },
                          tooltip: "Chọn file JSON",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: (_setNameController.text.trim().isEmpty || _selectedJsonFile == null)
                      ? null // Vô hiệu hóa nếu chưa nhập tên hoặc chọn file
                      : () async {
                    final setName = _setNameController.text.trim();
                    final setDescription = _setDescriptionController.text.trim();
                    final filePath = _selectedJsonFile!.path;

                    Navigator.of(dialogContext).pop(); // Đóng dialog trước khi xử lý

                    setState(() { _isLoading = true; }); // Hiển thị loading trên màn hình chính

                    try {
                      bool success = await _vocabDbService.importVocabularyFromJson(
                        filePath,
                        setName,
                        setDescription: setDescription.isNotEmpty ? setDescription : null,
                      );
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Nhập bộ từ '$setName' thành công!"), backgroundColor: Colors.green),
                        );
                        _loadVocabularySets(); // Tải lại danh sách
                      } else {
                        throw Exception("Không thêm được từ nào hoặc file không hợp lệ.");
                      }
                    } catch (e) {
                      developer.log("Lỗi khi nhập bộ từ '$setName'", name: _logName, error: e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi: Không thể nhập bộ từ. ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: Colors.red),
                      );
                    } finally {
                      if(mounted){ setState(() { _isLoading = false; });}
                    }
                  },
                  child: Text('Nhập & Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSet(VocabularySetModel set) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa bộ từ '${set.name}' không? Tất cả từ vựng trong bộ này cũng sẽ bị xóa."),
          actions: <Widget>[
            TextButton(child: Text("Hủy"), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(child: Text("Xóa", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );
    if (confirmDelete == true && set.id != null) {
      try {
        await _vocabDbService.deleteVocabularySet(set.id!); // Cần hàm này trong DBService
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã xóa bộ từ '${set.name}'"), backgroundColor: Colors.green),
        );
        _loadVocabularySets();
      } catch (e) {
        developer.log("Lỗi xóa bộ từ '${set.name}'", name: _logName, error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi xóa bộ từ."), backgroundColor: Colors.red),
        );
      }
    }
  }
  // void _showComingSoon(BuildContext context, String featureName) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$featureName sắp ra mắt!'),
  //       backgroundColor: Colors.blueGrey,
  //       duration: Duration(seconds: 1),
  //     ),
  //   );
  // }

  void _viewWordsInSet(VocabularySetModel set) {
    developer.log("Xem các từ trong bộ: ${set.name} (ID: ${set.id})", name: _logName);
    if (set.id == null) {
      developer.log("Lỗi: set.id là null, không thể xem chi tiết.", name: _logName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Không tìm thấy ID của bộ từ."), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularySetDetailScreen(
          setId: set.id!, // Truyền ID bộ từ
          setName: set.name, // Truyền tên bộ từ
        ),
      ),
    ).then((_) {
      // Sau khi quay lại từ VocabularySetDetailScreen, có thể cần tải lại danh sách bộ từ
      // nếu có thay đổi số lượng từ (ví dụ: sau khi thêm/xóa từ trong màn hình chi tiết)
      // Hiện tại chưa có chức năng sửa/xóa từ trong VocabularySetDetailScreen nên chưa cần thiết ngay.
      // _loadVocabularySets();
    });
  }

  Future<void> _studySetWithFlashcards(VocabularySetModel set) async {
    if (set.id == null) {
      developer.log("Lỗi: set.id là null, không thể học flashcards.", name: _logName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Không tìm thấy ID của bộ từ."), backgroundColor: Colors.red),
      );
      return;
    }

    developer.log("Chuẩn bị học flashcards cho bộ: ${set.name} (ID: ${set.id})", name: _logName);

    // Hiển thị loading tạm thời (nếu việc lấy từ mất thời gian)
    // setState(() { _isLoading = true; }); // Có thể cần một cờ loading riêng nếu không muốn che cả list

    try {
      final List<FlashcardItem> wordsInSet = await _vocabDbService.getVocabularyItemsBySetId(set.id!);

      if (!mounted) return;

      if (wordsInSet.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardScreen(
              flashcards: wordsInSet,
              setName: set.name, // Truyền tên bộ từ vào FlashcardScreen
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bộ từ '${set.name}' chưa có từ vựng nào để học!"), backgroundColor: Colors.orange),
        );
      }
    } catch (e, s) {
      developer.log("Lỗi khi tải từ vựng cho bộ '${set.name}' để học flashcards", name: _logName, error: e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi tải từ vựng: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      // if (mounted) { setState(() { _isLoading = false; }); }
    }
  }



  Widget _buildContent() {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    if (_vocabularySets.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sentiment_dissatisfied_rounded, size: 60, color: Colors.grey),
                SizedBox(height: 15),
                Text("Chưa có bộ từ vựng nào.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                SizedBox(height: 10),
                Text("Nhấn nút '+' để tạo hoặc nhập bộ từ mới từ file JSON.", textAlign: TextAlign.center),
              ],
            ),
          )
      );
    }
    return ListView.builder(
      itemCount: _vocabularySets.length,
      itemBuilder: (context, index) {
        final set = _vocabularySets[index];
        return VocabularySetListItem(
          set: set,
          onViewWords: () => _viewWordsInSet(set),
          onDeleteSet: () => _deleteSet(set), onStudyWithFlashcards: () => _studySetWithFlashcards(set),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý Bộ Từ Vựng"),
        backgroundColor: Colors.indigoAccent, // Màu riêng
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportSetDialog,
        icon: Icon(Icons.add_rounded),
        label: Text("Tạo/Nhập Bộ Từ"),
        tooltip: "Tạo bộ từ mới hoặc nhập từ file JSON",
        backgroundColor: Colors.deepOrangeAccent,
      ),
    );
  }
}