// lib/features/06_sempoa/screens/sempoa_challenge_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/sempoa_progress_model.dart';
import '../../../core/services/data_service.dart';

class SempoaChallengeScreen extends StatefulWidget {
  final SempoaProgress initialProgress;
  const SempoaChallengeScreen({super.key, required this.initialProgress});

  @override
  State<SempoaChallengeScreen> createState() => _SempoaChallengeScreenState();
}

class _SempoaChallengeScreenState extends State<SempoaChallengeScreen> {
  // --- Game State ---
  late int _currentLevel;
  late int _highScore;
  int _currentScore = 0;
  int _streak = 0;
  int _accuracyCount = 0;
  int _totalAttempts = 0;
  int _bestStreak = 0; // streak tertinggi dalam satu challenge
  
  // --- Timer State ---
  Timer? _timer;
  int _remainingSeconds = 60; // Waktu awal 60s (saran)
  final int _initialTime = 60;
  bool _isChallengeActive = false;

  // --- Sempoa State ---
  int _targetNumber = 0;
  int _currentSempoaValue = 0; // Nilai dari beads yang diklik
  final Random _random = Random();

  // --- Abacus (Sempoa) visual state ---
  // 4 kolom: Satuan, Puluhan, Ratusan, Ribuan
  final List<int> _placeValues = const [1, 10, 100, 1000];
  late List<bool> _topActive; // bead atas (nilai 5)
  late List<int> _bottomCount; // 0..4 bead bawah (nilai 1)

  // --- Feedback state ---
  bool? _lastCorrect; // null: belum cek, true: benar, false: salah

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialProgress.highestLevel;
    _highScore = widget.initialProgress.highScore;
    _topActive = List<bool>.filled(4, false);
    _bottomCount = List<int>.filled(4, 0);
    
    _generateTarget();
    // Challenge dimulai saat user menekan 'Mulai Challenge'
  }
  
  // --- Game Logic ---
  
  void _generateTarget() {
    // Target bertambah bertahap: Level 1=1..50, Level 2=1..100, dst.
    final int max = (50 * _currentLevel).clamp(50, 9999);
    const int min = 1;
    setState(() {
      _targetNumber = _random.nextInt(max - min + 1) + min;
      _currentSempoaValue = 0;
      _lastCorrect = null;
      _resetBeadsVisual(quiet: true);
    });
  }
  
  void _startChallenge() {
    setState(() {
      _isChallengeActive = true;
      _remainingSeconds = _initialTime;
      _currentLevel = 1; // Setiap mulai challenge baru, mulai dari Level 1
      _currentScore = 0;
      _streak = 0;
      _bestStreak = 0;
      _accuracyCount = 0;
      _totalAttempts = 0;
      _lastCorrect = null;
    });
    _generateTarget();
    _startTimer();
  }

  void _checkAnswer() {
    _totalAttempts++;
    if (_currentSempoaValue == _targetNumber) {
      // Jawaban Benar
      _accuracyCount++;
      _streak++;
  if (_streak > _bestStreak) _bestStreak = _streak; // catat streak terbaik
      _currentScore += 10; // Tambah 10 poin
      _remainingSeconds += 2; // Tambah waktu 2 detik
      _lastCorrect = true;
      
      _checkLevelUp();
      _generateTarget(); // Target baru
      _showFeedback(true);

    } else {
      // Jawaban Salah
      _streak = 0; // Streak putus
      _lastCorrect = false;
      _showFeedback(false);
    }
    
    // Perbarui High Score jika perlu
    if (_currentScore > _highScore) {
      _highScore = _currentScore;
    }
  }

  void _checkLevelUp() {
    // Logika level up sederhana: setiap 100 poin, naik level
    if (_currentScore >= 100 * _currentLevel) {
      setState(() {
        _currentLevel++;
        _remainingSeconds += 30; // Bonus waktu
        // TODO: Panggil saveProgress untuk level baru
      });
    }
  }
  
  void _showFeedback(bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'BENAR! +10 Poin, +2s' : 'SALAH! Streak putus.', style: const TextStyle(color: Colors.white)),
        backgroundColor: correct ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
  
  // --- Sempoa UI Logic ---

  // (metode lama _onBeadTapped dihapus, diganti dengan toggle visual)

  // Versi visual: toggle bead atas (nilai 5 x place) – tidak memaksa carry/borrow ke kolom lain
  void _toggleTop(int index) {
    setState(() {
      _topActive[index] = !_topActive[index];
      _recomputeFromBeads();
    });
  }

  // Tambah/Kurang beads bawah tanpa carry/borrow: 0..4 saja
  void _incrementBottom(int index) {
    setState(() {
      if (_bottomCount[index] < 4) {
        _bottomCount[index]++;
        _recomputeFromBeads();
      }
    });
  }

  void _decrementBottom(int index) {
    setState(() {
      if (_bottomCount[index] > 0) {
        _bottomCount[index]--;
        _recomputeFromBeads();
      }
    });
  }

  // ignore: unused_element
  void _applyDelta(int delta) {
    // Masih dipakai saat reset/penetapan nilai langsung jika diperlukan di masa depan
    setState(() {
      final int next = (_currentSempoaValue + delta).clamp(0, 9999);
      _setBeadsFromValue(next);
    });
  }

  void _setBeadsFromValue(int value) {
    _currentSempoaValue = value.clamp(0, 9999);
    for (int i = 0; i < 4; i++) {
      final int digit = (_currentSempoaValue ~/ _placeValues[i]) % 10;
      _topActive[i] = digit >= 5;
      _bottomCount[i] = digit % 5;
    }
  }

  void _recomputeFromBeads() {
    int sum = 0;
    for (int i = 0; i < 4; i++) {
      final five = _topActive[i] ? 5 : 0;
      final ones = _bottomCount[i];
      sum += (five + ones) * _placeValues[i];
    }
    _currentSempoaValue = sum.clamp(0, 9999);
  }

  void _resetSempoa() {
    setState(() {
      _currentSempoaValue = 0;
      _resetBeadsVisual(quiet: true);
    });
  }

  void _resetBeadsVisual({bool quiet = false}) {
    _topActive = List<bool>.filled(4, false);
    _bottomCount = List<int>.filled(4, 0);
    if (!quiet) setState(() {});
  }

  // --- Timer Logic ---

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _endChallenge();
      }
    });
  }
  
  void _endChallenge() {
    _saveAndStopChallenge(showResultDialog: true, title: 'Waktu Habis!', message: 'Skor Akhir Anda: $_currentScore');
  }

  void _saveAndStopChallenge({bool showResultDialog = false, String? title, String? message}) {
    _timer?.cancel();
    setState(() {
      _isChallengeActive = false;
    });
    // Simpan progres (skor tertinggi / level) ke backend
    DataService(context).saveSempoaProgress(newScore: _currentScore, newLevel: _currentLevel, newStreak: _bestStreak);
    if (showResultDialog) {
      showDialog(context: context, builder: (_) => AlertDialog(title: Text(title ?? 'Selesai'), content: Text(message ?? 'Skor: $_currentScore')));
    }
  }
  
  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    // Cek apakah waktu kritis (di bawah 10 detik)
    final bool isCriticalTime = _isChallengeActive && _remainingSeconds <= 10 && _remainingSeconds > 0;
    
    return WillPopScope(
      onWillPop: () async {
        if (_isChallengeActive) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Keluar dari Challenge?'),
              content: const Text('Jika keluar sekarang, waktu akan berhenti dan progres disimpan otomatis.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
              ],
            ),
          );
          if (confirm == true) {
            _saveAndStopChallenge(showResultDialog: false);
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text("Sempoa Digital"),
        backgroundColor: Colors.purple,
        actions: [
          // Tampilkan Timer
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _isChallengeActive ? _formatDuration(_remainingSeconds) : 'Siap',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isCriticalTime ? Colors.redAccent : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // [1] Kartu Statistik (Atas)
            _buildStatCards(),
            
            // [2] Target & Hasil (Tengah)
            _buildTargetAndResultCard(),
            
            // [3] Sempoa Interaktif (Visual)
            _buildSempoaVisuals(),
            
            // [4] Tombol Aksi
            _buildActionButtons(),
            
            // [5] Progress Level
            _buildLevelProgressCard(),
          ],
        ),
      ),
    ));
  }
  
  // Helper: Format Durasi (MM:SS)
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
  
  // ... (Anda harus membuat _buildStatCards, _buildTargetAndResultCard, _buildSempoaVisuals, _buildActionButtons, _buildLevelProgressCard) ...
  // Contoh:
  Widget _buildTargetAndResultCard() {
    // Sebelum challenge dimulai: panel hasil ringkas dan responsif
    if (!_isChallengeActive) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double vPad = w < 360 ? 12 : 18;
          final double titleSize = (w * 0.05).clamp(12, 16).toDouble();
          final double valueSize = (w * 0.18).clamp(28, 40).toDouble();
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
            decoration: BoxDecoration(
              color: const Color(0xFF2F6BFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Hasil saat ini:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: titleSize)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('$_currentSempoaValue',
                      style: TextStyle(color: Colors.white, fontSize: valueSize, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        }),
      );
    }

    // Saat challenge berjalan: tampilkan Target dan Nilai Sempoa berdampingan
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.indigo.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ResultDisplay(
                label: 'Target',
                value: '$_targetNumber',
                color: Colors.blue,
                hint: _lastCorrect == null
                    ? null
                    : (_lastCorrect! ? 'Benar!' : 'Coba lagi!'),
              ),
              _ResultDisplay(label: 'Nilai Sempoa', value: '$_currentSempoaValue', color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    // Tombol Cek Jawaban / Mulai Challenge
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _resetSempoa, 
              icon: const Icon(Icons.refresh), 
              label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Reset')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isChallengeActive ? _checkAnswer : _startChallenge,
              icon: Icon(_isChallengeActive ? Icons.check : Icons.flash_on, color: Colors.white, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isChallengeActive ? 'Cek Jawaban' : 'Mulai Challenge',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final accuracy = _totalAttempts == 0 ? 0 : ((_accuracyCount / _totalAttempts) * 100).round();
    final isCriticalTime = _isChallengeActive && _remainingSeconds <= 10 && _remainingSeconds > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Streak',
              value: '$_streak',
              color: Colors.purple,
              icon: Icons.local_fire_department_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Akurasi',
              value: '$accuracy%',
              color: Colors.indigo,
              icon: Icons.track_changes_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Waktu',
              value: _isChallengeActive ? '${_remainingSeconds}s' : '--',
              color: isCriticalTime ? Colors.red : Colors.blue,
              icon: Icons.timer_outlined,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSempoaVisuals() {
    const labels = ['Satuan', 'Puluhan', 'Ratusan', 'Ribuan'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double spacing = constraints.maxWidth < 360 ? 8 : 12;
              final double size = ((constraints.maxWidth - (spacing * 3)) / 4)
                  .clamp(48.0, 80.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Sempoa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Beads Atas (Nilai 5)', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => Padding(
                          padding: EdgeInsets.only(right: i == 3 ? 0 : spacing),
                          child: _TopBead(
                            active: _topActive[i],
                            label: labels[i],
                            onTap: () => _toggleTop(i),
                            size: size,
                          ),
                        )),
                  ),
                  const SizedBox(height: 16),
                  Text('Beads Bawah (Nilai 1)', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => Padding(
                          padding: EdgeInsets.only(right: i == 3 ? 0 : spacing),
                          child: _BottomBeads(
                            count: _bottomCount[i],
                            label: labels[i],
                            onIncrement: () => _incrementBottom(i),
                            onDecrement: () => _decrementBottom(i),
                            size: size,
                          ),
                        )),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildLevelProgressCard() {
    // Progres per-level berdasarkan 100 poin per level
    final int progress = (_currentScore % 100).clamp(0, 100);
    final double percent = progress / 100;
    final _TierStyle tier = _tierStyleForLevel(_currentLevel);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Card(
        color: Colors.purple.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Level $_currentLevel Progress', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: tier.bgColor, borderRadius: BorderRadius.circular(999)),
                    child: Text(tier.label, style: TextStyle(color: tier.textColor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: percent, minHeight: 10, backgroundColor: Colors.grey[300], color: tier.progressColor),
              const SizedBox(height: 8),
              Text('$progress / 100 poin ke level berikutnya', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}

// Kategori level untuk badge (Pemula, Menengah, Lanjutan, Ahli)
class _TierStyle {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color progressColor;
  const _TierStyle({required this.label, required this.bgColor, required this.textColor, required this.progressColor});
}

_TierStyle _tierStyleForLevel(int level) {
  if (level <= 3) {
    return const _TierStyle(
      label: 'Pemula',
      bgColor: Color(0xFFEAF8EF),
      textColor: Color(0xFF2DBE66),
      progressColor: Color(0xFF2DBE66),
    );
  } else if (level <= 6) {
    return const _TierStyle(
      label: 'Menengah',
      bgColor: Color(0xFFE8F0FE),
      textColor: Color(0xFF4285F4),
      progressColor: Color(0xFF4285F4),
    );
  } else if (level <= 9) {
    return const _TierStyle(
      label: 'Lanjutan',
      bgColor: Color(0xFFF3E8FF),
      textColor: Color(0xFF7A5CFF),
      progressColor: Color(0xFF7A5CFF),
    );
  } else {
    return const _TierStyle(
      label: 'Ahli',
      bgColor: Color(0xFFFFF4E5),
      textColor: Color(0xFFF59E0B),
      progressColor: Color(0xFFF59E0B),
    );
  }
}

// Widget untuk menampilkan Hasil/Target
class _ResultDisplay extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? hint; // opsional: 'Benar!' atau 'Coba lagi!'
  const _ResultDisplay({required this.label, required this.value, required this.color, this.hint});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;
      final double labelSize = (w * 0.12).clamp(12, 16).toDouble();
      final double valueSize = (w * 0.28).clamp(24, 40).toDouble();
      final double hintSize = (w * 0.10).clamp(12, 14).toDouble();
      return Column(
        children: [
          Text(label, style: TextStyle(fontSize: labelSize, color: Colors.grey[600])),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.bold, color: color)),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: TextStyle(
              fontSize: hintSize,
              fontWeight: FontWeight.w700,
              color: hint == 'Benar!' ? Colors.green : Colors.red,
            )),
          ],
        ],
      );
    });
  }
}

// ------------------------- Helper Widgets -------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;
      final double iconSize = (w * 0.2).clamp(18, 24).toDouble();
      final double box = iconSize + 12;
      final double titleSize = (w * 0.12).clamp(11, 14).toDouble();
      final double valueSize = (w * 0.18).clamp(13, 18).toDouble();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: box,
              height: box,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: titleSize),
                    ),
                  ),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: valueSize)),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    });
  }
}

class _TopBead extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;
  final double size;
  const _TopBead({required this.active, required this.label, required this.onTap, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEDE7FF) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Icon(Icons.circle, color: active ? const Color(0xFF7A5CFF) : Colors.grey, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey[700], fontSize: (size * 0.18).clamp(10, 12).toDouble()),
        ),
      ],
    );
  }
}

class _BottomBeads extends StatelessWidget {
  final int count; // 0..4
  final String label;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double size;
  const _BottomBeads({
    required this.count,
    required this.label,
    required this.onIncrement,
    required this.onDecrement,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final dy = details.localPosition.dy;
            if (dy <= size / 2) {
              onIncrement();
            } else {
              onDecrement();
            }
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: () {
                final double dotSize = (size * 0.16).clamp(6, 12).toDouble();
                final double vPad = (size * 0.04);
                return List.generate(4, (i) => Padding(
                      padding: EdgeInsets.symmetric(vertical: vPad),
                      child: Icon(
                        Icons.circle,
                        size: dotSize,
                        color: (i < count) ? const Color(0xFF3D7CFF) : Colors.grey[400],
                      ),
                    ));
              }(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey[700], fontSize: (size * 0.18).clamp(10, 12).toDouble()),
        ),
      ],
    );
  }
}