// lib/service/game_selection_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class GameSelectionService {
  static const _selectedSetsKey = 'selected_game_sets';

  // Lưu một danh sách các ID của bộ từ
  Future<void> saveSelectedSets(Set<String> setIds) async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences có thể lưu một List<String>
    await prefs.setStringList(_selectedSetsKey, setIds.toList());
  }

  // Tải danh sách ID của các bộ từ đã lưu
  Future<Set<String>> loadSelectedSets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? setIds = prefs.getStringList(_selectedSetsKey);
    return setIds?.toSet() ?? {}; // Trả về một Set rỗng nếu chưa có
  }
}