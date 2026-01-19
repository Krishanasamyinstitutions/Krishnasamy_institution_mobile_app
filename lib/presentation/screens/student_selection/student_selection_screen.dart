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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top Navigation - Back Button
            _buildTopNavigation(),
            const SizedBox(height: 32),
            // Header with Title and Illustration
            _buildHeader(),
            const SizedBox(height: 56),
            // Student List
            Expanded(
              child: _buildStudentList(),
            ),
            // Continue Button
            _buildContinueButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3D75FC).withValues(alpha: 0.24),
                    blurRadius: 1,
                    offset: Offset.zero,
                  ),
                  const BoxShadow(
                    color: Color(0xFFE5E7EB),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF1F2933),
                ),
              ),
            ),
          ),
          // Empty space for balance (no filter button in design)
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Student',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2933),
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6B7280),
                  height: 1.47,
                ),
              ),
            ],
          ),
          // Illustration
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
          return const Center(
            child: Text(
              'No students found for this parent',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final student = students[index];
            final isSelected = _selectedStudentId == student.stuId;
            return _buildStudentCard(student, isSelected);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(StudentModel student, bool isSelected) {
    // TODO: Determine payment status from fee data - for now showing as Pending
    final isPending = true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStudentId = student.stuId;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Button
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: isSelected
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1F2933),
                          width: 2,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admission No.
                  const Text(
                    'Admission No.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.stuadmno,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF1F2933),
                      height: 1.47,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Name and Class Row
                  Row(
                    children: [
                      const Text(
                        'Name :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          student.stuname,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF1F2933),
                            height: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '|',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Class :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        student.stuclass,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF1F2933),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF2DBE60),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPending ? 'Pending' : 'Paid',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppSizes.fontSemibold,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _selectedStudentId != null
            ? () async {
                // Get the selected student and save to provider
                final studentsAsync = ref.read(studentsByParentProvider);
                studentsAsync.whenData((students) async {
                  final selectedStudent = students.firstWhere(
                    (s) => s.stuId == _selectedStudentId,
                  );
                  // Use selectStudent method for persistence
                  await ref.read(selectedStudentProvider.notifier).selectStudent(selectedStudent);
                });
                // Navigate to home screen
                context.go(Routes.home);
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _selectedStudentId != null
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D75FC).withValues(alpha: 0.24),
                blurRadius: 1,
                offset: Offset.zero,
              ),
              const BoxShadow(
                color: Color(0xFFE5E7EB),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: AppSizes.fontSemibold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Icon(
                Icons.arrow_forward,
                size: 24,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
