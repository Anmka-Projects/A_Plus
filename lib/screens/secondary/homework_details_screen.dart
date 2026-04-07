import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../services/homeworks_service.dart';

/// Homework details & submission screen.
/// Supports MCQ, true/false, text, and file upload answers for students.
class HomeworkDetailsScreen extends StatefulWidget {
  final String homeworkId;

  const HomeworkDetailsScreen({
    super.key,
    required this.homeworkId,
  });

  @override
  State<HomeworkDetailsScreen> createState() => _HomeworkDetailsScreenState();
}

class _HomeworkDetailsScreenState extends State<HomeworkDetailsScreen> {
  Map<String, dynamic>? _homework;
  Map<String, dynamic>? _mySubmission;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// Local answer state: questionId -> answer payload (matches API schema)
  final Map<String, dynamic> _answers = {};

  /// For file answers: questionId -> picked file
  final Map<String, File> _fileAnswers = {};

  /// Per-question result from submission: isCorrect, score, etc.
  final Map<String, Map<String, dynamic>> _questionResults = {};

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hw =
          await HomeworksService.instance.getHomeworkDetails(widget.homeworkId);
      Map<String, dynamic>? mySub;
      try {
        mySub = await HomeworksService.instance
            .getMyHomeworkSubmission(widget.homeworkId);
      } catch (_) {
        // 404 or not submitted yet – ignore
      }

      if (!mounted) return;
      setState(() {
        _homework = hw;
        _mySubmission = mySub;
        _isLoading = false;
      });

      // Pre-fill answers from existing submission if available
      if (mySub != null) {
        _prefillAnswersFromSubmission(mySub);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _prefillAnswersFromSubmission(Map<String, dynamic> submission) {
    final answers = submission['answers'];
    if (answers is! List) return;

    _questionResults.clear();

    for (final raw in answers.whereType<Map>()) {
      final answer = Map<String, dynamic>.from(raw);
      final qId = answer['questionId']?.toString();
      if (qId == null) continue;
      _answers[qId] = {
        'question_id': qId,
        'selected_option_id': answer['selectedOptionId'],
        'boolean_answer': answer['booleanAnswer'],
        'text_answer': answer['textAnswer'],
        // For file answers, we only have filePath – keep as-is; new upload overwrites
      };

      // Store correctness & score for UI display
      final isCorrect = answer['isCorrect'];
      final score = answer['score'];
      if (isCorrect != null || score != null) {
        _questionResults[qId] = {
          'isCorrect': isCorrect,
          'score': score,
        };
      }
    }
  }

  Future<void> _pickFileForQuestion(String questionId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'],
      );
      final path = result?.files.singleOrNull?.path;
      if (path == null || path.trim().isEmpty) return;
      final file = File(path.trim());
      setState(() {
        _fileAnswers[questionId] = file;
        // Basic payload; actual file is attached in multipart request
        _answers[questionId] = {
          'question_id': questionId,
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر اختيار الملف. حاول مرة أخرى.',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit({required bool asDraft}) async {
    if (_homework == null) return;

    setState(() {
      _isSubmitting = true;
    });
    try {
      await HomeworksService.instance.submitHomework(
        widget.homeworkId,
        action: asDraft ? 'draft' : 'submit',
        answers: _answers.values.cast<Map<String, dynamic>>().toList(),
        fileAnswers: _fileAnswers,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asDraft ? 'تم حفظ المسودة بنجاح' : 'تم إرسال الواجب بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      await _loadHomework();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _homework?['title']?.toString() ?? 'تفاصيل الواجب',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: _buildBody(theme),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.destructive),
              const SizedBox(height: 12),
              Text(
                'تعذر تحميل بيانات الواجب',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHomework,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hw = _homework;
    if (hw == null) {
      return const SizedBox.shrink();
    }

    final description = hw['description']?.toString() ?? '';
    final questions = hw['questions'] is List
        ? (hw['questions'] as List).whereType<Map>().toList()
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoChips(hw),
          const SizedBox(height: 24),
          Text(
            'الأسئلة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          if (questions.isEmpty)
            Text(
              'لا توجد أسئلة في هذا الواجب.',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            )
          else
            ...List.generate(
              questions.length,
              (index) => _buildQuestionCard(
                Map<String, dynamic>.from(questions[index]),
                index + 1,
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoChips(Map<String, dynamic> hw) {
    final totalMarks = hw['totalMarks'];
    final dueDateText = hw['dueDate']?.toString();
    final course = hw['course'] as Map<String, dynamic>?;
    final myTotalScore = _mySubmission?['totalScore'];

    num? parsedTotalMarks;
    if (totalMarks != null) {
      if (totalMarks is num) {
        parsedTotalMarks = totalMarks;
      } else {
        parsedTotalMarks = num.tryParse(totalMarks.toString());
      }
    }

    num? parsedMyScore;
    if (myTotalScore != null) {
      if (myTotalScore is num) {
        parsedMyScore = myTotalScore;
      } else {
        parsedMyScore = num.tryParse(myTotalScore.toString());
      }
    }

    bool? isPassed;
    if (parsedTotalMarks != null && parsedMyScore != null) {
      // If backend provides an explicit passing score, prefer it; otherwise use 50% threshold.
      final passingScoreRaw = hw['passingScore'] ?? hw['passMarks'];
      num passingScore;
      if (passingScoreRaw is num) {
        passingScore = passingScoreRaw;
      } else if (passingScoreRaw != null) {
        passingScore = num.tryParse(passingScoreRaw.toString()) ??
            (parsedTotalMarks * 0.5);
      } else {
        passingScore = parsedTotalMarks * 0.5;
      }
      isPassed = parsedMyScore >= passingScore;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsedTotalMarks != null && parsedMyScore != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (isPassed ?? false)
                  ? const Color(0xFFE6F9F0)
                  : const Color(0xFFFFF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isPassed ?? false)
                    ? const Color(0xFF16A34A)
                    : AppColors.destructive.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (isPassed ?? false)
                      ? Icons.emoji_events_rounded
                      : Icons.warning_rounded,
                  color: (isPassed ?? false)
                      ? const Color(0xFF16A34A)
                      : AppColors.destructive,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'درجتك النهائية',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${parsedMyScore.toInt()} / ${parsedTotalMarks.toInt()}',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: (isPassed ?? false)
                                  ? const Color(0xFF16A34A)
                                  : AppColors.destructive,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isPassed ?? false)
                                  ? const Color(0xFF16A34A)
                                  : AppColors.destructive,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isPassed ?? false ? 'ناجح' : 'غير ناجح',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (course != null)
              _buildInfoChip(
                icon: Icons.school_rounded,
                label: course['name']?.toString() ?? 'الدورة',
              ),
            if (totalMarks != null)
              _buildInfoChip(
                icon: Icons.grade_rounded,
                label: 'الدرجة الكلية: $totalMarks',
              ),
            if (dueDateText != null && dueDateText.isNotEmpty)
              _buildInfoChip(
                icon: Icons.schedule_rounded,
                label: 'آخر موعد: ${dueDateText.split('T').first}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.purple),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int number) {
    final id = question['id']?.toString() ?? '';
    final type = question['type']?.toString() ?? 'mcq';
    final text = question['questionText']?.toString() ??
        question['question_text']?.toString() ??
        '';
    final marks = question['marks'];

    final current = _answers[id] as Map<String, dynamic>? ?? {};
    final result = _questionResults[id];
    final bool? isCorrect =
        result != null ? result['isCorrect'] as bool? : null;
    final num? questionScore;
    if (result != null && result['score'] != null) {
      if (result['score'] is num) {
        questionScore = result['score'] as num;
      } else {
        questionScore = num.tryParse(result['score'].toString());
      }
    } else {
      questionScore = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.purple.withOpacity(0.1),
                  child: Text(
                    number.toString(),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      if (marks != null || questionScore != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (marks != null)
                              Text(
                                '$marks درجة',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            if (marks != null && questionScore != null)
                              const SizedBox(width: 8),
                            if (questionScore != null)
                              Text(
                                'درجتك: ${questionScore.toInt()}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCorrect != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isCorrect
                          ? const Color(0xFF10B981)
                          : AppColors.destructive,
                      size: 22,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (type == 'mcq')
              _buildMcqOptions(question, id, current)
            else if (type == 'true_false')
              _buildTrueFalseOptions(id, current)
            else if (type == 'text')
              _buildTextAnswerField(id, current)
            else if (type == 'file_upload')
              _buildFileUploadField(id),
          ],
        ),
      ),
    );
  }

  Widget _buildMcqOptions(
    Map<String, dynamic> question,
    String questionId,
    Map<String, dynamic> current,
  ) {
    final options = question['options'] is List
        ? (question['options'] as List).whereType<Map>().toList()
        : <Map<String, dynamic>>[];
    final selectedId = current['selected_option_id']?.toString();

    return Column(
      children: options.map((opt) {
        final optId = opt['id']?.toString() ??
            opt['optionId']?.toString() ??
            opt['option_id']?.toString();
        final text = opt['optionText']?.toString() ??
            opt['option_text']?.toString() ??
            '';
        if (optId == null) return const SizedBox.shrink();
        final isSelected = optId == selectedId;

        return InkWell(
          onTap: () {
            setState(() {
              _answers[questionId] = {
                'question_id': questionId,
                'selected_option_id': optId,
              };
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple.withOpacity(0.08)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.purple
                    : AppColors.purple.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color:
                      isSelected ? AppColors.purple : AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(
    String questionId,
    Map<String, dynamic> current,
  ) {
    final bool? value = current['boolean_answer'] as bool?;

    Widget buildOption(bool optionValue, String label) {
      final isSelected = value == optionValue;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              _answers[questionId] = {
                'question_id': questionId,
                'boolean_answer': optionValue,
              };
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple.withOpacity(0.08)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.purple
                    : AppColors.purple.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color:
                      isSelected ? AppColors.purple : AppColors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildOption(true, 'صح'),
        const SizedBox(width: 8),
        buildOption(false, 'خطأ'),
      ],
    );
  }

  Widget _buildTextAnswerField(
    String questionId,
    Map<String, dynamic> current,
  ) {
    final controller = TextEditingController(
      text: current['text_answer']?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      maxLines: 4,
      onChanged: (value) {
        _answers[questionId] = {
          'question_id': questionId,
          'text_answer': value.trim(),
        };
      },
      decoration: InputDecoration(
        hintText: 'اكتب إجابتك هنا...',
        hintStyle: GoogleFonts.cairo(
          color: AppColors.mutedForeground,
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.purple.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.purple,
            width: 1.2,
          ),
        ),
      ),
      style: GoogleFonts.cairo(
        fontSize: 13,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildFileUploadField(String questionId) {
    final file = _fileAnswers[questionId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickFileForQuestion(questionId),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
            foregroundColor: AppColors.purple,
          ),
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(
            file == null ? 'اختيار ملف (PDF / صورة / ZIP)' : 'تغيير الملف',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.insert_drive_file_rounded,
                  size: 18, color: AppColors.purple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  file.path.split(Platform.pathSeparator).last,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    final hw = _homework;
    if (hw == null) return const SizedBox.shrink();

    final myStatus = _mySubmission?['status']?.toString();
    final isSubmitted = myStatus == 'submitted' || myStatus == 'graded';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _submit(asDraft: true),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
                ),
                child: Text(
                  'حفظ كمسودة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting || isSubmitted
                    ? null
                    : () => _submit(asDraft: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isSubmitted ? 'تم الإرسال' : 'إرسال الواجب',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
