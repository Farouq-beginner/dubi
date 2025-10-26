// screens/quiz_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/answer_model.dart';
import '../../../core/services/data_service.dart';
import '../../04_lesson/screens/quiz_result_screen.dart'; // Layar baru

class QuizScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  const QuizScreen({Key? key, required this.quizId, required this.quizTitle}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<Quiz> _quizFuture;
  late DataService _dataService;
  
  // State untuk UI
  PageController _pageController = PageController();
  List<Question> _questions = [];
  bool _isLoading = false;

  // State untuk menyimpan jawaban siswa
  // Map<question_id, answer_id>
  final Map<int, int> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);
    _quizFuture = _dataService.fetchQuizDetails(widget.quizId);
  }
  
  void _onAnswerSelected(int questionId, int answerId) {
    setState(() {
      _selectedAnswers[questionId] = answerId;
    });
  }
  
  Future<void> _submitQuiz() async {
    setState(() => _isLoading = true);
    
    // Konversi Map ke List format: [{'question_id': 1, 'answer_id': 3}, ...]
    final List<Map<String, int>> answersList = _selectedAnswers.entries.map((e) {
      return {'question_id': e.key, 'answer_id': e.value};
    }).toList();

    try {
      final results = await _dataService.submitQuiz(widget.quizId, answersList);
      
      if (!mounted) return;
      // Navigasi ke Halaman Hasil
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.questions == null) {
            return Center(child: Text('Kuis tidak valid.'));
          }

          _questions = snapshot.data!.questions!;
          
          return Column(
            children: [
              Expanded(
                // PageView untuk swipe antar pertanyaan
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(), // Nonaktifkan swipe manual
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return _buildQuestionCard(question, index + 1, _questions.length);
                  },
                ),
              ),
              
              // --- Tombol Navigasi Bawah ---
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )
              else
                _buildNavigationControls(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildNavigationControls() {
    // Cek halaman saat ini
    int currentPage = _pageController.positions.isEmpty ? 0 : _pageController.page!.round();
    bool isLastPage = currentPage == _questions.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali
          TextButton(
            child: Text('Kembali'),
            onPressed: currentPage == 0 ? null : () { // Nonaktifkan di halaman pertama
              _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
            },
          ),
          
          // Tombol Lanjut / Selesai
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isLastPage ? Colors.green : Colors.deepPurple),
            child: Text(isLastPage ? 'Selesai Kuis' : 'Lanjut', style: TextStyle(color: Colors.white)),
            onPressed: () {
              // Cek apakah siswa sudah menjawab
              int currentQuestionId = _questions[currentPage].questionId;
              if (!_selectedAnswers.containsKey(currentQuestionId)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Harap pilih satu jawaban!'), backgroundColor: Colors.orange),
                );
                return;
              }

              if (isLastPage) {
                // Tampilkan konfirmasi
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Kumpulkan Kuis?'),
                    content: Text('Anda yakin ingin menyelesaikan kuis ini?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Batal')),
                      ElevatedButton(onPressed: () {
                        Navigator.of(ctx).pop();
                        _submitQuiz();
                      }, child: Text('Ya, Kumpulkan!')),
                    ],
                  )
                );
              } else {
                _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
              }
            },
          ),
        ],
      ),
    );
  }
  
  // Tampilan satu kartu pertanyaan
  Widget _buildQuestionCard(Question question, int questionNumber, int totalQuestions) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indikator Progres
          Text(
            'Pertanyaan $questionNumber dari $totalQuestions',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),
          // Teks Pertanyaan
          Text(
            question.questionText,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          
          // --- Pilihan Jawaban ---
          ...question.answers.map((Answer answer) {
            bool isSelected = _selectedAnswers[question.questionId] == answer.answerId;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _onAnswerSelected(question.questionId, answer.answerId),
                child: Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple[50] : Colors.grey[100],
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.deepPurple : Colors.grey[600],
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(answer.answerText, style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}