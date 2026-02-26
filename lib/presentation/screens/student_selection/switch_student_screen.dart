import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../../data/models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

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

    return DesktopDetailScaffold(
      isNested: true,
      header: _buildHeader(context),
      toolbar: const BreadcrumbBar(
        parentLabel: 'Profile',
        parentRoute: Routes.profile,
        currentLabel: 'Switch Student',
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (students) => _buildStudentList(students, currentStudent),
      ),
      bottomBar: _buildSwitchButton(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (!context.isDesktop)
            GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(Routes.profile);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderC(context)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch Student',
                  style: TextStyle(
                    fontSize: context.isDesktop ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a different student profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryC(context),
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
      padding: context.isDesktop
          ? const EdgeInsets.all(24)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderC(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primary600],
                ),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: student.photoUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (context, url) => Center(
                        child: Text(
                          _getInitials(student.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          _getInitials(student.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(student.name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryC(context),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryC(context),
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
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            color: isNewSelection ? null : AppColors.borderC(context),
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
                  color: isNewSelection ? Colors.white : AppColors.textHintC(context),
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
    final students = studentsAsync.valueOrNull;
    if (students == null) return;

    final selectedStudent = students.firstWhere(
      (s) => s.stuId == _selectedStudentId,
    );

    await ref.read(selectedStudentProvider.notifier).selectStudent(selectedStudent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${selectedStudent.name}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.go(Routes.home);
    }
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
