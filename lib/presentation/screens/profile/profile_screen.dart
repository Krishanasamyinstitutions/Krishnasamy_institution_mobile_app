import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/institution_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final currentParent = ref.watch(currentParentProvider);
    final hasMultipleStudents = ref.watch(hasMultipleStudentsProvider);

    final Map<String, String> studentData = selectedStudent != null
        ? {
            'name': selectedStudent.name,
            'class': selectedStudent.className,
            'adminNo': selectedStudent.admissionNumber,
            'gender': selectedStudent.gender,
            'dob': _formatDate(selectedStudent.dateOfBirth),
            'blood': selectedStudent.stubloodgrp ?? 'N/A',
            'mobile': currentParent?.payinchargemob ?? 'N/A',
            'email': currentParent?.paremail ?? 'N/A',
            'address': selectedStudent.fullAddress.isNotEmpty ? selectedStudent.fullAddress : 'N/A',
            'parentName': currentParent?.payincharge ?? 'N/A',
          }
        : {
            'name': 'Student',
            'class': 'N/A',
            'adminNo': 'N/A',
            'gender': 'N/A',
            'dob': 'N/A',
            'blood': 'N/A',
            'mobile': 'N/A',
            'email': 'N/A',
            'address': 'N/A',
            'parentName': 'N/A',
          };

    if (context.isDesktop) {
      return _buildDesktopProfile(context, studentData, hasMultipleStudents);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
          // Mobile: shadow header
          Container(
            color: AppColors.headerBg(context),
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.headerBg(context),
                  boxShadow: AppColors.cardShadow(context),
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

          // Mobile: single scroll column
          Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildStudentCard(studentData),
                      const SizedBox(height: 20),
                      _buildSchoolInfoWidget(context),
                      const SizedBox(height: 20),
                      _buildQuickActionsSection(context, hasMultipleStudents),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _InfoItem(icon: Icons.badge_outlined, label: 'Admission No', value: studentData['adminNo']!),
                        _InfoItem(icon: Icons.school_outlined, label: 'Class', value: studentData['class']!),
                        _InfoItem(
                          icon: studentData['gender'] == 'Male'
                              ? Icons.male
                              : studentData['gender'] == 'Female'
                                  ? Icons.female
                                  : Icons.wc_outlined,
                          label: 'Gender',
                          value: studentData['gender']!,
                        ),
                        _InfoItem(icon: Icons.cake_outlined, label: 'Date of Birth', value: studentData['dob']!),
                        _InfoItem(icon: Icons.water_drop_outlined, label: 'Blood Group', value: studentData['blood']!),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _InfoItem(icon: Icons.person_outline_rounded, label: 'Student In-Charge', value: studentData['parentName']!),
                        _InfoItem(icon: Icons.phone_android_rounded, label: 'Mobile', value: studentData['mobile']!, isNotProvided: studentData['mobile'] == 'N/A'),
                        _InfoItem(icon: Icons.email_outlined, label: 'Email', value: studentData['email']!),
                        _InfoItem(icon: Icons.location_on_outlined, label: 'Address', value: studentData['address']!, isNotProvided: studentData['address'] == 'N/A'),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopProfile(
      BuildContext context, Map<String, String> studentData, bool hasMultipleStudents) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Student card → Quick Actions → Personal Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentCard(studentData),
                const SizedBox(height: 16),
                _buildDesktopQuickActions(context, hasMultipleStudents),
                const SizedBox(height: 16),
                _buildDesktopSectionCard(
                  context,
                  title: 'Personal Information',
                  child: _buildInfoCardContent([
                    _InfoItem(icon: Icons.badge_outlined, label: 'Admission No', value: studentData['adminNo']!),
                    _InfoItem(icon: Icons.school_outlined, label: 'Class', value: studentData['class']!),
                    _InfoItem(
                      icon: studentData['gender'] == 'Male'
                          ? Icons.male
                          : studentData['gender'] == 'Female'
                              ? Icons.female
                              : Icons.wc_outlined,
                      label: 'Gender',
                      value: studentData['gender']!,
                    ),
                    _InfoItem(icon: Icons.cake_outlined, label: 'Date of Birth', value: studentData['dob']!),
                    _InfoItem(icon: Icons.water_drop_outlined, label: 'Blood Group', value: studentData['blood']!),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right column: School card → Contact Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopSchoolCard(context),
                const SizedBox(height: 16),
                _buildDesktopSectionCard(
                  context,
                  title: 'Contact Information',
                  child: _buildInfoCardContent([
                    _InfoItem(icon: Icons.person_outline_rounded, label: 'Student In-Charge', value: studentData['parentName']!),
                    _InfoItem(icon: Icons.phone_android_rounded, label: 'Mobile', value: studentData['mobile']!, isNotProvided: studentData['mobile'] == 'N/A'),
                    _InfoItem(icon: Icons.email_outlined, label: 'Email', value: studentData['email']!),
                    _InfoItem(icon: Icons.location_on_outlined, label: 'Address', value: studentData['address']!, isNotProvided: studentData['address'] == 'N/A'),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A floating card section with a title header for desktop profile.
  Widget _buildDesktopSectionCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Info card content without outer container (used inside _buildDesktopSectionCard).
  Widget _buildInfoCardContent(List<_InfoItem> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;
        return Column(
          children: [
            _buildInfoRow(item),
            if (!isLast) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppColors.borderC(context),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ),
          ),
          // Cart Icon - Dark theme
          GestureDetector(
            onTap: () => context.push(Routes.cart),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/Cart.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          cartItemCount > 9 ? '9+' : '$cartItemCount',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Notification Icon - Dark theme
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/notification.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopQuickActions(BuildContext context, bool hasMultipleStudents) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (hasMultipleStudents) ...[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(Routes.switchStudent),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        label: const Text('Switch Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(Routes.support),
                      icon: const Icon(Icons.support_agent_rounded, size: 20),
                      label: const Text('Get Support'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSchoolCard(BuildContext context) {
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    final institution = institutionAsync.valueOrNull;
    final schoolName = institution?.name ?? 'School';
    final schoolAddress = institution?.shortAddress ?? 'Address not available';
    final schoolEmail = institution?.email;
    final schoolPhone = institution?.phone;
    final schoolMotto = institution?.motto;
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cardBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasLogo
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Text(
                                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondaryC(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              schoolAddress,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondaryC(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (schoolMotto != null && schoolMotto.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schoolMotto,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (schoolEmail != null || schoolPhone != null) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: AppColors.borderC(context)),
              const SizedBox(height: 16),
              if (schoolEmail != null && schoolEmail.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: schoolPhone != null && schoolPhone.isNotEmpty ? 12 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: AppColors.textSecondaryC(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHintC(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              schoolEmail,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimaryC(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (schoolPhone != null && schoolPhone.isNotEmpty)
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textHintC(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            schoolPhone,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryC(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, String> studentData) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final hasPhoto = selectedStudent != null && selectedStudent.photoUrl != null && selectedStudent.photoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: [
          // Large Avatar - tappable
          GestureDetector(
            onTap: () => _showProfileImagePopup(
              context,
              studentData['name']!,
              hasPhoto ? selectedStudent.photoUrl! : null,
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: hasPhoto
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primary600],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: selectedStudent.photoUrl!,
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                      placeholder: (context, url) => Center(
                        child: Text(
                          _getInitials(studentData['name']!),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primary600],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(studentData['name']!),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(studentData['name']!),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentData['name']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.cardGreenDark),
                      const SizedBox(width: 4),
                      Text(
                        'Active Student',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cardGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool hasMultipleStudents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryC(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Switch Student
            if (hasMultipleStudents) ...[
              Expanded(
                child: _buildActionCard(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Switch Student',
                  bgColor: AppColors.cardBlue,
                  iconColor: AppColors.cardBlueDark,
                  onTap: () => context.push(Routes.switchStudent),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Get Support
            Expanded(
              child: _buildActionCard(
                icon: Icons.support_agent_rounded,
                label: 'Get Support',
                bgColor: AppColors.cardCyan,
                iconColor: AppColors.cardCyanDark,
                onTap: () => context.push(Routes.support),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    IconData? icon,
    String? svgPath,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                      )
                    : Icon(icon, size: 22, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryC(context),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            return Column(
              children: [
                _buildInfoRow(item),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: AppColors.borderC(context),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: item.svgPath != null
                ? SvgPicture.asset(
                    item.svgPath!,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      AppColors.textSecondaryC(context),
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(
                    item.icon,
                    size: 20,
                    color: AppColors.textSecondaryC(context),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHintC(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.isNotProvided ? 'Not provided' : item.value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: item.isNotProvided
                      ? AppColors.textDisabled
                      : AppColors.textPrimaryC(context),
                  fontStyle: item.isNotProvided ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolInfoWidget(BuildContext context) {
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    final institution = institutionAsync.valueOrNull;
    final schoolName = institution?.name ?? 'School';
    final schoolAddress = institution?.shortAddress ?? 'Address not available';
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasLogo
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Text(
                          schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondaryC(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schoolAddress,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryC(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileImagePopup(BuildContext context, String name, String? photoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Profile image
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: photoUrl == null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primary600],
                      )
                    : null,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 200,
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primary600],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(name),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Student name
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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

class _InfoItem {
  final IconData? icon;
  final String? svgPath;
  final String label;
  final String value;
  final bool isNotProvided;

  _InfoItem({
    this.icon,
    this.svgPath,
    required this.label,
    required this.value,
    this.isNotProvided = false,
  }) : assert(icon != null || svgPath != null, 'Either icon or svgPath must be provided');
}
