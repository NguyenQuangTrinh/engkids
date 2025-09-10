// lib/screens/vocabulary/vocabulary_set_management_screen.dart

import 'package:engkids/screens/vocabulary/vocabulary_set_detail_screen.dart';
import 'package:engkids/service/firebase_vocabulary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vocabulary_set_model.dart';
import '../../providers/vocabulary_providers.dart';
import '../../widgets/vocabulary/import_set_dialog.dart';
import '../../widgets/vocabulary/vocabulary_set_list_item.dart';
import 'flashcard_screen.dart';
import '../../service/vocabulary_database_service.dart';

class VocabularySetManagementScreen extends ConsumerWidget {
  const VocabularySetManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSets = ref.watch(vocabularySetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Bộ Từ Vựng"),
        backgroundColor: Colors.indigoAccent,
      ),
      body: asyncSets.when(
        data: (sets) {
          if (sets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Chưa có bộ từ vựng nào.",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Nhấn nút '+' để tạo hoặc nhập bộ từ mới.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(vocabularySetsProvider),
            child: ListView.builder(
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];
                return VocabularySetListItem(
                  set: set,
                  onViewWords: () => _viewWordsInSet(context, set),
                  // <<< THAY ĐỔI LỚN BẮT ĐẦU TỪ ĐÂY
                  onShare: () => _toggleSharing(ref, set),
                  onDeleteSet: () async {
                    // Logic xóa được đưa trực tiếp vào đây
                    final bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Xác nhận xóa"),
                          content: Text(
                            "Bạn có chắc chắn muốn xóa bộ từ '${set.name}' không?",
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("Hủy"),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: const Text(
                                "Xóa",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete == true && set.id != null) {
                      // Dùng `ref.read` và `.notifier` để gọi hàm
                      await ref
                          .read(vocabularySetsProvider.notifier)
                          .deleteSet(set.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã xóa bộ từ '${set.name}'"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  // <<< KẾT THÚC THAY ĐỔI
                  onStudyWithFlashcards:
                      () => _studySetWithFlashcards(context, set),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) =>
                Center(child: Text("Lỗi tải dữ liệu: $error")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showImportSetDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Tạo/Nhập Bộ Từ"),
        backgroundColor: Colors.deepOrangeAccent,
      ),
    );
  }

  // <<< XÓA BỎ HÀM _deleteSet() RIÊNG LẺ KHỎI ĐÂY

  // Các hàm còn lại giữ nguyên
  Future<void> _showImportSetDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const ImportSetDialogContent();
      },
    );
  }

  Future<void> _toggleSharing(WidgetRef ref, VocabularySetModel set) async {
    if (set.id == null) return;
    try {
      await FirebaseVocabularyService.instance.toggleSetSharing(
        set.id!,
        set.isPublic,
      );
      ref.invalidate(vocabularySetsProvider); // Làm mới UI
    } catch (e) {
      // Xử lý lỗi
    }
  }

  void _viewWordsInSet(BuildContext context, VocabularySetModel set) {
    if (set.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VocabularySetDetailScreen(
              setId: set.id!,
              setName: set.name,
              ownerId: set.ownerId!,
            ),
      ),
    );
  }

  Future<void> _studySetWithFlashcards(
    BuildContext context,
    VocabularySetModel set,
  ) async {
    if (set.id == null) return;
    try {
      // Dùng read để lấy service, không dùng instance trực tiếp
      final items = await VocabularyDatabaseService.instance
          .getVocabularyItemsBySetId(set.id!);
      if (context.mounted) {
        if (items.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      FlashcardScreen(flashcards: items, setName: set.name),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bộ từ '${set.name}' chưa có từ vựng!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi tải từ vựng: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
