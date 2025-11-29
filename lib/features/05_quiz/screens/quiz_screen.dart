// lib/features/05_quiz/screens/quiz_screen.dart
import 'dart:async';
import 'package:dubi/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/answer_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/local_notification_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  // [KEMBALIKAN KE PARAMETER LAMA]
  final int quizId;
  final String quizTitle;
  const QuizScreen({Key? key, required this.quizId, required this.quizTitle})
    : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late DataService _dataService;
  late Future<Quiz> _quizFuture; // <-- Future untuk memuat data kuis

  // State untuk UI
  final PageController _pageController = PageController();
  List<Question> _questions = [];
  bool _isLoading = false;

  // State untuk Timer
  Timer? _timer;
  int _remainingSeconds = 0;

  final Map<int, int> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);

    // [PERBAIKAN] Panggil API untuk mendapatkan data kuis lengkap
    _quizFuture = _dataService.fetchQuizDetails(widget.quizId);

    // Kita akan memulai timer SETELAH data dimuat di FutureBuilder
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer(int durationInMinutes) {
    if (durationInMinutes > 0) {
      _remainingSeconds = durationInMinutes * 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          _submitQuiz(autoSubmit: true);
        }
      });
    }
  }

  void _onAnswerSelected(int questionId, int answerId) {
    setState(() {
      _selectedAnswers[questionId] = answerId;
    });
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _timer?.cancel();

    final List<Map<String, int>> answersList = _selectedAnswers.entries.map((
      e,
    ) {
      return {'question_id': e.key, 'answer_id': e.value};
    }).toList();

    try {
      final results = await _dataService.submitQuiz(
        widget.quizId,
        answersList,
      ); // <-- Gunakan widget.quizId

      if (!mounted) return;

      // Ini akan memaksa AuthProvider untuk cek ke server berapa jumlah notif sekarang
      await Provider.of<AuthProvider>(context, listen: false).checkUnreadNotifications();

      // --- [BARU] TAMPILKAN NOTIFIKASI DI STATUS BAR HP ---
      LocalNotificationService.showNotification(
        title: 'Kuis Selesai! 🎉',
        body: 'Hebat! Anda menyelesaikan kuis "${widget.quizTitle}" dengan skor ${results['score']}.'
      );

      if (autoSubmit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu habis! Kuis telah dikumpulkan.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            score: results['score'],
            totalQuestions: results['total_questions'],
            correctAnswers: results['correct_answers'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fungsi Peringatan Keluar (Sama seperti sebelumnya)
  Future<bool> _showExitWarning() async {
    // ... (Kode showDialog warning) ...
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Kuis?'),
        content: const Text(
          'Jika Anda keluar, kuis akan otomatis dikumpulkan. Jawaban yang belum diisi akan dianggap salah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: const Text(
              'Ya, Keluar & Kumpulkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Helper format durasi
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _showExitWarning();
        if (shouldPop) {
          _submitQuiz(autoSubmit: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.quizTitle,
            style: TextStyle(color: Colors.white),
          ), // <-- Gunakan widget.quizTitle
          centerTitle: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 4, 31, 184),
                  Color.fromARGB(255, 77, 80, 255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          automaticallyImplyLeading: true,
          actions: [
            if (_timer != null) // Tampilkan Timer jika sudah aktif
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _formatDuration(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: FutureBuilder<Quiz>(
          future: _quizFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Error memuat kuis: ${snapshot.error.toString()}"),
              );
            }
            if (!snapshot.hasData ||
                snapshot.data!.questions == null ||
                snapshot.data!.questions!.isEmpty) {
              return const Center(
                child: Text("Kuis ini tidak memiliki pertanyaan."),
              );
            }

            // --- DATA KUIS DARI API SUDAH LENGKAP ---
            final quizData = snapshot.data!;
            _questions = quizData.questions!; // Set questions

            // Cek apakah timer perlu dimulai (Hanya sekali!)
            if (_timer == null &&
                quizData.duration != null &&
                quizData.duration! > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startTimer(quizData.duration!);
              });
            }

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return _buildQuestionCard(
                        question,
                        index + 1,
                        _questions.length,
                      );
                    },
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  _buildNavigationControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  // Tampilan Kontrol Navigasi Bawah
  Widget _buildNavigationControls() {
    int currentPage = _pageController.positions.isEmpty
        ? 0
        : _pageController.page!.round();
    bool isLastPage = currentPage == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: currentPage == 0
                ? null
                : () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
            child: const Text('Sebelumnya'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastPage ? Colors.green : Colors.deepPurple,
            ),
            onPressed: () {
              int currentQuestionId = _questions[currentPage].questionId;
              if (!_selectedAnswers.containsKey(currentQuestionId)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap pilih satu jawaban!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (isLastPage) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Kumpulkan Kuis?'),
                    content: const Text(
                      'Anda yakin ingin menyelesaikan kuis ini?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _submitQuiz(autoSubmit: false);
                        },
                        child: const Text('Ya, Kumpulkan!'),
                      ),
                    ],
                  ),
                );
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
            child: Text(
              isLastPage ? 'Selesai Kuis' : 'Lanjut',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan satu kartu pertanyaan
  Widget _buildQuestionCard(
    Question question,
    int questionNumber,
    int totalQuestions,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan $questionNumber dari $totalQuestions',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          ...question.answers.map((Answer answer) {
            bool isSelected =
                _selectedAnswers[question.questionId] == answer.answerId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () =>
                    _onAnswerSelected(question.questionId, answer.answerId),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple[50]
                        : Colors.grey[100],
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          answer.answerText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
