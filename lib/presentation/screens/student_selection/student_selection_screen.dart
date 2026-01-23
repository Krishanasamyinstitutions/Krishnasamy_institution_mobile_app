import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';
import '../../../data/models/student_model.dart';
import '../../providers/student_provider.dart';

class StudentSelectionScreen extends ConsumerStatefulWidget {
  const StudentSelectionScreen({super.key});

  @override
  ConsumerState<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends ConsumerState<StudentSelectionScreen> {
  int? _selectedStudentId;
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    // Check for single student after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSingleStudent();
    });
  }

  Future<void> _checkForSingleStudent() async {
    if (_hasAutoSelected) return;

    final studentsAsync = ref.read(studentsByParentProvider);
    studentsAsync.whenData((students) async {
      if (students.length == 1 && mounted) {
        _hasAutoSelected = true;
        // Auto-select the only student and navigate to home
        final student = students.first;
        await ref.read(selectedStudentProvider.notifier).selectStudent(student);
        if (mounted) {
          context.go(Routes.home);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for students loading and auto-select if single student
    ref.listen<AsyncValue<List<StudentModel>>>(studentsByParentProvider, (previous, next) {
      next.whenData((students) async {
        if (students.length == 1 && !_hasAutoSelected && mounted) {
          _hasAutoSelected = true;
          final student = students.first;
          await ref.read(selectedStudentProvider.notifier).selectStudent(student);
          if (mounted) {
            context.go(Routes.home);
          }
        }
      });
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Header with white SafeArea and subtle shadow
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTopNavigation(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _buildStudentList(),
                  ),
                  _buildContinueButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Student',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a student to continue',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/select_student_illustration.png',
            width: 120,
            height: 100,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final studentsAsync = ref.watch(studentsByParentProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading students: $error'),
      ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cardPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off_rounded,
                    size: 40,
                    color: AppColors.cardPurpleDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No students found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final student = students[index];
            final isSelected = _selectedStudentId == student.stuId;
            return _buildStudentCard(student, isSelected, index);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(StudentModel student, bool isSelected, int index) {
    final cardColors = [
      {'bg': AppColors.cardPurple, 'icon': AppColors.cardPurpleDark},
      {'bg': AppColors.cardGreen, 'icon': AppColors.cardGreenDark},
      {'bg': AppColors.cardBlue, 'icon': AppColors.cardBlueDark},
      {'bg': AppColors.cardPink, 'icon': AppColors.cardPinkDark},
    ];
    final colorSet = cardColors[index % cardColors.length];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStudentId = student.stuId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.shadowPurple : AppColors.shadowLight,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar - Circular like home page
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorSet['bg'],
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
              ),
              child: Center(
                child: Text(
                  student.stuname.isNotEmpty ? student.stuname[0].toUpperCase() : 'S',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorSet['icon'],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Student Info - Home page style
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.stuname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Adm No: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        TextSpan(
                          text: student.stuadmno,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const TextSpan(
                          text: ' | Class: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        TextSpan(
                          text: student.stuclass,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedStudentId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: isEnabled
            ? () async {
                final studentsAsync = ref.read(studentsByParentProvider);
                studentsAsync.whenData((students) async {
                  final selectedStudent = students.firstWhere(
                    (s) => s.stuId == _selectedStudentId,
                  );
                  await ref.read(selectedStudentProvider.notifier).selectStudent(selectedStudent);
                });
                context.go(Routes.home);
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primary600],
                  )
                : null,
            color: isEnabled ? null : AppColors.gray300,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? Colors.white : AppColors.textDisabled,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: isEnabled ? Colors.white : AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
