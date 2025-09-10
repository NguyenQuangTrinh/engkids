// lib/providers/vocabulary_providers.dart

import 'package:engkids/models/flashcard_item_model.dart';
import 'package:engkids/providers/auth_provider.dart';
import 'package:engkids/service/firebase_vocabulary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocabulary_set_model.dart';

// 1. TẠO CLASS NOTIFIER
// Class này sẽ quản lý state (danh sách các bộ từ) và chứa các hàm để thay đổi state đó.
class VocabularySetsNotifier
    extends StateNotifier<AsyncValue<List<VocabularySetModel>>> {
  final _vocabService = FirebaseVocabularyService.instance;

  // Constructor: Khi Notifier được tạo, nó ở trạng thái loading và bắt đầu tải dữ liệu
  VocabularySetsNotifier() : super(const AsyncValue.loading()) {
    fetchSets();
  }

  // Hàm để tải dữ liệu
  Future<void> fetchSets() async {
    if (FirebaseAuth.instance.currentUser == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final sets = await _vocabService.getVocabularyFeed();
      if (mounted) {
        state = AsyncValue.data(sets);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  // Hàm để xóa một bộ từ
  Future<void> deleteSet(String setId) async {
    try {
      await _vocabService.deleteVocabularySet(setId);
      // Không cần gọi fetchSets() nữa, invalidate sẽ tự làm
      await fetchSets();
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  // Hàm để thêm một bộ từ (sau khi import từ JSON)
  Future<void> addSetByImport(
    String filePath,
    String setName, {
    String? setDescription,
  }) async {
    try {
      final success = await _vocabService.importVocabularyFromJsonString(
        filePath,
        setName,
        setDescription: setDescription,
      );
      if (success) {
        await fetchSets(); // Tải lại danh sách sau khi thêm thành công
      } else {
        throw Exception("Không thêm được từ nào từ file JSON.");
      }
    } catch (e) {
      // Ném lại lỗi để UI có thể bắt và hiển thị
      rethrow;
    }
  }
}

final vocabularySetsProvider = StateNotifierProvider<
  VocabularySetsNotifier,
  AsyncValue<List<VocabularySetModel>>
>((ref) {
  ref.watch(authStateChangesProvider);
  return VocabularySetsNotifier();
});

@immutable
class SetDetailsArgs {
  final String ownerId;
  final String setId;

  const SetDetailsArgs({required this.ownerId, required this.setId});

  // Ghi đè operator và hashCode để Riverpod biết khi nào tham số thay đổi
  @override
  bool operator ==(Object other) =>
      other is SetDetailsArgs &&
      other.ownerId == ownerId &&
      other.setId == setId;

  @override
  int get hashCode => Object.hash(ownerId, setId);
}

final vocabularyItemsProvider =
    FutureProvider.family<List<FlashcardItem>, SetDetailsArgs>((ref, args) {
      // .family cho phép chúng ta nhận một tham số (ở đây là setId)
      final vocabService = FirebaseVocabularyService.instance;
      return vocabService.getVocabularyItemsBySetId(args.ownerId, args.setId);
    });

final combinedVocabularyProvider =
    FutureProvider.family<List<FlashcardItem>, Set<VocabularySetModel>>((
      ref,
      sets,
    ) {
      if (sets.isEmpty) return [];
      return FirebaseVocabularyService.instance.getItemsFromMultipleSets(
        sets.toList(),
      );
    });
