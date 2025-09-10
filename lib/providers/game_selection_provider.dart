// lib/providers/game_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:engkids/models/vocabulary_set_model.dart';
import 'package:engkids/providers/vocabulary_providers.dart';
import 'package:engkids/service/game_selection_service.dart';

// Notifier để quản lý state
class GameSelectionNotifier
    extends StateNotifier<AsyncValue<Set<VocabularySetModel>>> {
  final GameSelectionService _selectionService = GameSelectionService();
  // `ref` để đọc các provider khác
  final Ref _ref;

  GameSelectionNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadInitialSelection();
  }

  // Tải lựa chọn đã lưu và cả danh sách các bộ từ có sẵn
  Future<void> _loadInitialSelection() async {
    try {
      // 1. Tải các ID đã lưu từ SharedPreferences
      final savedSetIds = await _selectionService.loadSelectedSets();

      // 2. Yêu cầu Notifier kia tải dữ liệu và đợi nó hoàn thành
      await _ref.read(vocabularySetsProvider.notifier).fetchSets();

      // 3. Bây giờ, đọc state đã được tải xong của vocabularySetsProvider
      final allAvailableSets =
          _ref.read(vocabularySetsProvider).asData?.value ?? [];

      // 4. Lọc ra các object VocabularySetModel tương ứng với các ID đã lưu
      final selectedSets =
          allAvailableSets.where((set) => savedSetIds.contains(set.id)).toSet();

      if (mounted) {
        state = AsyncValue.data(selectedSets);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  // Cập nhật và lưu lựa chọn mới
  Future<void> updateSelection(Set<VocabularySetModel> newSelection) async {
    final setIds = newSelection.map((set) => set.id!).toSet();
    await _selectionService.saveSelectedSets(setIds);
    // Cập nhật state để UI lắng nghe có thể rebuild
    state = AsyncValue.data(newSelection);
  }
}

// StateNotifierProvider
final gameSelectionProvider = StateNotifierProvider<
  GameSelectionNotifier,
  AsyncValue<Set<VocabularySetModel>>
>((ref) {
  return GameSelectionNotifier(ref);
});
