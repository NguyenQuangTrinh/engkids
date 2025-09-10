// lib/screens/vocabulary/game_set_selection_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vocabulary_set_model.dart';
import '../../providers/game_selection_provider.dart';
import '../../providers/vocabulary_providers.dart';

class GameSetSelectionScreen extends ConsumerStatefulWidget {
  // Bỏ tham số gameRoute vì màn hình này giờ chỉ có 1 nhiệm vụ: chọn và lưu
  const GameSetSelectionScreen({super.key});

  @override
  ConsumerState<GameSetSelectionScreen> createState() => _GameSetSelectionScreenState();
}

class _GameSetSelectionScreenState extends ConsumerState<GameSetSelectionScreen> {
  // State cục bộ để quản lý các lựa chọn đang được thay đổi
  late Set<VocabularySetModel> _currentlySelectedSets;
  
  @override
  void initState() {
    super.initState();
    // Khởi tạo lựa chọn ban đầu bằng dữ liệu từ provider
    final savedSelection = ref.read(gameSelectionProvider);
    _currentlySelectedSets = Set.from(savedSelection.asData?.value ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final asyncSets = ref.watch(vocabularySetsProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tùy chỉnh Bộ từ để chơi"),
        backgroundColor: Colors.indigoAccent,
      ),
      body: asyncSets.when(
        data: (sets) {
          if (sets.isEmpty) {
            return const Center(child: Text("Không có bộ từ nào để chọn."));
          }
          return ListView.builder(
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              // Dùng _currentlySelectedSets để kiểm tra
              final isSelected = _currentlySelectedSets.any((selected) => selected.id == set.id);
              final bool isMySet = set.ownerId == currentUserId;

              return CheckboxListTile(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _currentlySelectedSets.add(set);
                    } else {
                      _currentlySelectedSets.removeWhere((s) => s.id == set.id);
                    }
                  });
                },
                title: Text(set.name),
                subtitle: Text(
                  isMySet ? "Bộ từ của bạn (${set.wordCount} từ)" : "Của ${set.ownerName} (${set.wordCount} từ)",
                  style: TextStyle(color: isMySet ? Colors.blue : Colors.teal),
                ),
                secondary: Icon(isMySet ? Icons.person_rounded : Icons.group_rounded),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Lỗi: $err")),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Gọi notifier để cập nhật và lưu lựa chọn
            ref.read(gameSelectionProvider.notifier).updateSelection(_currentlySelectedSets);
            Navigator.of(context).pop(); // Quay về màn hình trước
          },
          label: const Text("Lưu Lựa Chọn"),
          icon: const Icon(Icons.check_rounded),
          backgroundColor: Colors.green,
        ),
    );
  }
}