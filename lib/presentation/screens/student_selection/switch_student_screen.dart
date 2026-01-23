import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../../data/models/student_model.dart';
import '../../providers/student_provider.dart';

class SwitchStudentScreen extends ConsumerStatefulWidget {
  const SwitchStudentScreen({super.key});

  @override
  ConsumerState<SwitchStudentScreen> createState() => _SwitchStudentScreenState();
}

class _SwitchStudentScreenState extends ConsumerState<SwitchStudentScreen> {
  int? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    // Pre-select current student
    final currentStudent = ref.read(selectedStudentProvider);
    if (currentStudent != null) {
      _selectedStudentId = currentStudent.stuId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsByParentProvider);
    final currentStudent = ref.watch(selectedStudentProvider);

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
                    _buildHeader(context),
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
                  _buildTitle(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: studentsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error: $error')),
                      data: (students) => _buildStudentList(students, currentStudent),
                    ),
                  ),
                  _buildSwitchButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Back Button - Dark theme
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
          const SizedBox(width: 12),
          // Title & Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch Student',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a different student',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.people_rounded,
              size: 24,
              color: AppColors.cardBlueDark,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Children',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to select, then confirm below',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentModel> students, StudentModel? currentStudent) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        final isSelected = _selectedStudentId == student.stuId;
        final isCurrent = currentStudent?.stuId == student.stuId;

        return _buildStudentCard(student, isSelected, isCurrent);
      },
    );
  }

  Widget _buildStudentCard(StudentModel student, bool isSelected, bool isCurrent) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStudentId = student.stuId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(student.name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.cardGreenDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cardGreenDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Adm No: ${student.admissionNumber} | Class: ${student.className}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchButton() {
    final currentStudent = ref.watch(selectedStudentProvider);
    final isNewSelection = _selectedStudentId != null && _selectedStudentId != currentStudent?.stuId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: isNewSelection ? _handleSwitch : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isNewSelection
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primary600],
                  )
                : null,
            color: isNewSelection ? null : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isNewSelection
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
                isNewSelection ? 'Switch Student' : 'Select a Different Student',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isNewSelection ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
              if (isNewSelection) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSwitch() async {
    if (_selectedStudentId == null) return;

    final studentsAsync = ref.read(studentsByParentProvider);
    studentsAsync.whenData((students) async {
      final selectedStudent = students.firstWhere(
        (s) => s.stuId == _selectedStudentId,
      );

      await ref.read(selectedStudentProvider.notifier).selectStudent(selectedStudent);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${selectedStudent.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Navigate to home
        context.go(Routes.home);
      }
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
