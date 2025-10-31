// lib/features/06_sempoa/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final DataService _dataService;
  late Future<List<LeaderboardItem>> _future;

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);
    _future = _dataService.fetchSempoaLeaderboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _dataService.fetchSempoaLeaderboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard Sempoa'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<LeaderboardItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text('Gagal memuat leaderboard: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? const <LeaderboardItem>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Belum ada data leaderboard.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final rank = index + 1;
                final isTop3 = rank <= 3;
                final color = isTop3
                    ? (rank == 1
                        ? const Color(0xFFFFD700)
                        : rank == 2
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFCD7F32))
                    : Colors.green.shade50;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                    child: ListTile(
                    contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: isTop3 ? color : Colors.green.shade100,
                      child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isTop3 ? Colors.black : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                    title: Row(
                      children: [
                      Expanded(
                        child: Text(
                        item.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ],
                    ),
                    subtitle: LayoutBuilder(
                      builder: (context, constraints) {
                      // divide available width so each chip can shrink when needed
                      final maxChipWidth = (constraints.maxWidth - 32) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxChipWidth),
                          child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _StatChip(
                            icon: Icons.star,
                            label: 'Level',
                            value: '${item.highestLevel}',
                          ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxChipWidth),
                          child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _StatChip(
                            icon: Icons.bolt,
                            label: 'Skor',
                            value: '${item.highScore}',
                          ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxChipWidth),
                          child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _StatChip(
                            icon: Icons.local_fire_department,
                            label: 'Streak',
                            value: '${item.highestStreak}',
                          ),
                          ),
                        ),
                        ],
                      );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text('$label: $value', style: TextStyle(color: Colors.green.shade900)),
        ],
      ),
    );
  }
}
