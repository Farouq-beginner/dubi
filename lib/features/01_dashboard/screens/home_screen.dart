// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/data_service.dart';
import 'package:dubi/features/03_course/screens/course_detail_screen.dart';
import '../../../core/models/level_model.dart';
import '../../../core/models/subject_model.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/course_card_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Course>> _coursesFuture;
  late DataService _dataService;

  // Filters & search
  int? _selectedLevelId; // null = Semua
  int? _selectedSubjectId; // null = Semua
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  // Lock behavior for student with fixed jenjang (non-Umum)
  bool _isLockedToLevel = false;
  int? _lockedLevelId; // set from AuthProvider for student

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _coursesFuture = _dataService.fetchMyCourses(); // Panggil API dinamis

    // Determine whether this user is locked to a specific jenjang
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.user?.role ?? 'student';
    final userLevelId = auth.user?.levelId;
    _isLockedToLevel =
        role == 'student' && userLevelId != null; // Umum has null level_id
    _lockedLevelId = _isLockedToLevel ? userLevelId : null;
    if (_isLockedToLevel) {
      _selectedLevelId = _lockedLevelId; // force filter
    }
  }

  // Fungsi untuk refresh
  Future<void> _refreshCourses() async {
    setState(() {
      _coursesFuture = _dataService.fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshCourses,
        child: FutureBuilder<List<Course>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Belum ada kursus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ),
              );
            }

            final List<Course> courses = snapshot.data!;

            // Build choices from data
            final levelMap = <int, Level>{};
            final subjectMap = <int, Subject>{};
            for (final c in courses) {
              if (c.level != null) levelMap[c.level!.levelId] = c.level!;
              subjectMap[c.subject.subjectId] = c.subject;
            }
            final levels = levelMap.values.toList()
              ..sort((a, b) => a.levelName.compareTo(b.levelName));
            final subjects = subjectMap.values.toList()
              ..sort((a, b) => a.subjectName.compareTo(b.subjectName));

            // Apply filters and search
            final filtered = courses.where((c) {
              final matchLevel =
                  _selectedLevelId == null ||
                  (c.level?.levelId == _selectedLevelId);
              final matchSubject =
                  _selectedSubjectId == null ||
                  c.subject.subjectId == _selectedSubjectId;
              final matchSearch =
                  _search.isEmpty ||
                  c.title.toLowerCase().contains(_search.toLowerCase());
              return matchLevel && matchSubject && matchSearch;
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header + Search
                LayoutBuilder(
                  builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  final lockedLevelName = _isLockedToLevel
                    ? levels
                      .firstWhere(
                        (l) => l.levelId == _lockedLevelId,
                        orElse: () => Level(
                        levelId: -1,
                        levelName: '',
                        courses: const [],
                        ),
                      )
                      .levelName
                    : '';
                  final header = Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                    const Text(
                      'Semua Course',
                      style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_isLockedToLevel && lockedLevelName.isNotEmpty)
                      _LevelBadge(text: lockedLevelName),
                    ],
                  );
                  final searchField = SizedBox(
                    width: isNarrow ? double.infinity : 220,
                    child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari',
                      border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                      ),
                    ),
                    ),
                  );
                  if (isNarrow) {
                    return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 12),
                      searchField,
                    ],
                    );
                  }
                  return Row(
                    children: [
                    Expanded(child: header),
                    searchField,
                    ],
                  );
                  },
                ),

                const SizedBox(height: 12),

                // Fixed order level chips at top (Semua, TK, SD, SMP, SMA)
                if (!_isLockedToLevel)
                  _FilterSection(
                    title: '',
                    chips: [
                      FilterChipData(
                        label: 'Semua',
                        selected: _selectedLevelId == null,
                        onSelected: () =>
                            setState(() => _selectedLevelId = null),
                      ),
                      ...['TK', 'SD', 'SMP', 'SMA'].map((name) {
                        final lvl = levels.firstWhere(
                          (l) => l.levelName.toUpperCase() == name,
                          orElse: () => Level(
                            levelId: -1,
                            levelName: name,
                            courses: const [],
                          ),
                        );
                        final selected =
                            _selectedLevelId != null &&
                            _selectedLevelId == lvl.levelId;
                        return FilterChipData(
                          label: name,
                          selected: selected,
                          onSelected: () => setState(
                            () => _selectedLevelId = lvl.levelId == -1
                                ? null
                                : lvl.levelId,
                          ),
                        );
                      }),
                    ],
                  ),

                const SizedBox(height: 8),

                // Subjects chips (Semua plus derived subjects)
                _FilterSection(
                  title: '',
                  chips: [
                    FilterChipData(
                      label: 'Semua',
                      selected: _selectedSubjectId == null,
                      onSelected: () =>
                          setState(() => _selectedSubjectId = null),
                    ),
                    ...subjects.map(
                      (s) => FilterChipData(
                        label: s.subjectName,
                        selected: _selectedSubjectId == s.subjectId,
                        onSelected: () =>
                            setState(() => _selectedSubjectId = s.subjectId),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ...filtered.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CourseCardItem(
                      course: c,
                      levelTag: c.level?.levelName,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(course: c),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('Tidak ada kursus dengan filter saat ini.'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      // Tidak ada FAB untuk semua role agar konsisten seperti mock
      floatingActionButton: null,
    );
  }
}

// Kapsul kecil untuk label jenjang di samping judul
class _LevelBadge extends StatelessWidget {
  final String text;
  const _LevelBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  FilterChipData({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
}

class _FilterSection extends StatelessWidget {
  final String title; // optional label, unused when ''
  final List<FilterChipData> chips;
  const _FilterSection({required this.title, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...chips.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(d.label),
                    selected: d.selected,
                    onSelected: (_) => d.onSelected(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
