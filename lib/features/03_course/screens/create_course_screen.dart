// screens/create_course_screen.dart
import 'package:flutter/material.dart' hide Subject; // <-- PERBAIKAN 1: Sembunyikan 'Subject' dari material
import '../../../core/services/data_service.dart';
import '../../../core/models/level_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/course_model.dart';


class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  _CreateCourseScreenState createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  // Kunci untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // Controller untuk input teks
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Variabel untuk menyimpan data dropdown
  int? _selectedLevelId;
  int? _selectedSubjectId;

  // Variabel untuk data dari API
  late Future<List<Level>> _levelsFuture;
  late Future<List<Subject>> _subjectsFuture;

  // State untuk loading saat submit
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Panggil DataService untuk mengambil data dropdown saat halaman dibuka
    // Kita butuh 'context' di sini, jadi kita tidak bisa panggil di 'didChangeDependencies'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cek jika widget masih ada di tree
      if(mounted) {
        final dataService = DataService(context);
        setState(() {
          _levelsFuture = dataService.fetchLevels();
          _subjectsFuture = dataService.fetchSubjects();
        });
      }
    });
  }

  // Fungsi untuk submit form
Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Jika form tidak valid, stop
    }

    setState(() => _isLoading = true);

    try {
      final dataService = DataService(context);
      
      // --- [PERBAIKAN] ---
      // Panggil createCourse, yang sekarang mengembalikan Objek Course
      final Course newCourse = await dataService.createCourse(
        title: _titleController.text,
        description: _descriptionController.text,
        levelId: _selectedLevelId!,
        subjectId: _selectedSubjectId!,
      );
      // --------------------

      if (!mounted) return; 

      // Tampilkan pesan sukses (kita bisa pakai nama kursus yg baru)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kursus "${newCourse.title}" berhasil dibuat!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Kembali ke home
    
    } catch (e) {
      // JALUR GAGAL:
      // 'e' adalah String error yang kita 'throw' dari data_service
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Kursus Baru'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Judul ---
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration('Judul Kursus'),
                validator: (val) => val!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),

              // --- Deskripsi ---
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration('Deskripsi Kursus'),
                maxLines: 4,
                validator: (val) => val!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),

              // --- Dropdown Jenjang (Level) ---
              FutureBuilder<List<Level>>(
                future: _levelsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text('Gagal memuat jenjang');
                  }
                  
                  return DropdownButtonFormField<int>(
                    decoration: _buildInputDecoration('Pilih Jenjang'),
                    value: _selectedLevelId,
                    hint: Text('Pilih Jenjang (TK/SD...)'),
                    items: snapshot.data!.map((level) {
                      return DropdownMenuItem(
                        value: level.levelId,
                        child: Text(level.levelName),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedLevelId = val),
                    validator: (val) => val == null ? 'Jenjang wajib dipilih' : null,
                    isExpanded: true, // Tambahan: agar teks panjang tidak terpotong
                  );
                },
              ),
              SizedBox(height: 16),

              // --- Dropdown Mata Pelajaran (Subject) ---
              // 'Subject' di sini sekarang tidak akan error lagi
              FutureBuilder<List<Subject>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text('Gagal memuat mata pelajaran');
                  }
                  
                  return DropdownButtonFormField<int>(
                    decoration: _buildInputDecoration('Pilih Mata Pelajaran'),
                    value: _selectedSubjectId,
                    hint: Text('Pilih Mata Pelajaran'),
                    items: snapshot.data!.map((subject) {
                      return DropdownMenuItem(
                        value: subject.subjectId,
                        child: Text(subject.subjectName),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                    validator: (val) => val == null ? 'Mapel wajib dipilih' : null,
                    isExpanded: true, // Tambahan: agar teks panjang tidak terpotong
                  );
                },
              ),
              SizedBox(height: 32),

              // --- Tombol Submit ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ), // Nonaktifkan saat loading
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('SIMPAN KURSUS', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper dekorasi input
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}