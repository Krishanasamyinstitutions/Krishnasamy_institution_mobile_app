import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';
import 'auth_provider.dart' show supabaseClientProvider, parentAuthStateProvider;
import 'cart_provider.dart';

/// Set to false to use Supabase data, true for dummy data
const bool useDummyData = false;

/// Key for persisting selected student ID
const String _selectedStudentIdKey = 'selected_student_id';

/// Currently selected student - managed by StateNotifier for persistence
final selectedStudentProvider = StateNotifierProvider<SelectedStudentNotifier, StudentModel?>((ref) {
  return SelectedStudentNotifier(ref);
});

/// Notifier that handles student selection with persistence
class SelectedStudentNotifier extends StateNotifier<StudentModel?> {
  final Ref _ref;
  bool _manuallySelected = false;

  SelectedStudentNotifier(this._ref) : super(null) {
    _loadSavedStudent();
  }

  /// Load saved student from SharedPreferences
  Future<void> _loadSavedStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStudentId = prefs.getInt(_selectedStudentIdKey);

      if (savedStudentId != null) {
        debugPrint('Loading saved student ID: $savedStudentId');

        // If user already selected a student manually, don't overwrite
        if (_manuallySelected) {
          debugPrint('Student already selected manually, skipping saved load');
          return;
        }

        final client = _ref.read(supabaseClientProvider);

        final response = await client
            .from('students')
            .select('*')
            .eq('stu_id', savedStudentId)
            .eq('activestatus', 1)
            .maybeSingle();

        // Check again after async gap — user may have selected during DB fetch
        if (_manuallySelected) {
          debugPrint('Student was selected during load, skipping');
          return;
        }

        if (response != null) {
          state = StudentModel.fromJson(response);
          debugPrint('Loaded student: ${state?.name}');
        }
      }
    } catch (e) {
      debugPrint('Error loading saved student: $e');
    }
  }

  /// Save student selection to SharedPreferences
  Future<void> _saveStudent(int? studentId) async {
    final prefs = await SharedPreferences.getInstance();
    if (studentId != null) {
      await prefs.setInt(_selectedStudentIdKey, studentId);
    } else {
      await prefs.remove(_selectedStudentIdKey);
    }
  }

  /// Select a student
  Future<void> selectStudent(StudentModel student) async {
    _manuallySelected = true;

    // Clear cart when switching students
    final currentStudentId = state?.stuId;
    if (currentStudentId != null && currentStudentId != student.stuId) {
      _ref.read(cartProvider.notifier).clearCartLocal();
      debugPrint('Cart cleared for student switch');
    }

    state = student;
    await _saveStudent(student.stuId);
    debugPrint('Selected student: ${student.name}');
  }

  /// Clear selection (on logout)
  Future<void> clearSelection() async {
    state = null;
    await _saveStudent(null);
  }
}

/// Fetch students by parent ID (used after login)
/// Uses parentdetail table to link parents to students
final studentsByParentProvider = FutureProvider<List<StudentModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final parentAuthState = ref.watch(parentAuthStateProvider);

  final parent = parentAuthState.valueOrNull?.parent;
  if (parent == null) {
    return [];
  }

  try {
    // First, get student IDs from parentdetail table
    final parentDetailResponse = await client
        .from('parentdetail')
        .select('stu_id')
        .eq('par_id', parent.parId);

    final studentIds = (parentDetailResponse as List<dynamic>)
        .map((e) => e['stu_id'] as int)
        .toList();

    if (studentIds.isEmpty) {
      debugPrint('No students linked to parent ${parent.parId}');
      return [];
    }

    // Then fetch the actual student records
    final response = await client
        .from('students')
        .select('*')
        .inFilter('stu_id', studentIds)
        .eq('activestatus', 1)
        .order('stuname', ascending: true);

    return (response as List<dynamic>)
        .map((e) => StudentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching students by parent: $e');
    return [];
  }
});

/// Fetch all students from Supabase
final studentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('students')
        .select('*')
        .eq('activestatus', 1)
        .order('stuname', ascending: true);

    return (response as List<dynamic>)
        .map((e) => StudentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching students: $e');
    return [];
  }
});

/// Fetch students by institution ID
final studentsByInstitutionProvider = FutureProvider.family<List<StudentModel>, int>((ref, insId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('students')
        .select('*')
        .eq('ins_id', insId)
        .eq('activestatus', 1)
        .order('stuname', ascending: true);

    return (response as List<dynamic>)
        .map((e) => StudentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching students by institution: $e');
    return [];
  }
});

/// Fetch a single student by ID
final studentByIdProvider = FutureProvider.family<StudentModel?, int>((ref, stuId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('students')
        .select('*')
        .eq('stu_id', stuId)
        .maybeSingle();

    if (response != null) {
      return StudentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching student by ID: $e');
    return null;
  }
});

/// Fetch student by mobile number (for login)
final studentByMobileProvider = FutureProvider.family<StudentModel?, String>((ref, mobile) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('students')
        .select('*')
        .eq('stumobile', mobile)
        .eq('activestatus', 1)
        .maybeSingle();

    if (response != null) {
      return StudentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching student by mobile: $e');
    return null;
  }
});

/// Fetch student by admission number
final studentByAdmissionProvider = FutureProvider.family<StudentModel?, String>((ref, admNo) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('students')
        .select('*')
        .eq('stuadmno', admNo)
        .eq('activestatus', 1)
        .maybeSingle();

    if (response != null) {
      return StudentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching student by admission number: $e');
    return null;
  }
});

/// Provider to check if parent has multiple students
final hasMultipleStudentsProvider = Provider<bool>((ref) {
  final studentsAsync = ref.watch(studentsByParentProvider);
  return studentsAsync.maybeWhen(
    data: (students) => students.length > 1,
    orElse: () => false,
  );
});

/// Provider to get student count
final studentCountProvider = Provider<int>((ref) {
  final studentsAsync = ref.watch(studentsByParentProvider);
  return studentsAsync.maybeWhen(
    data: (students) => students.length,
    orElse: () => 0,
  );
});

/// Fetch institution for selected student based on ins_id
final selectedStudentWithInstitutionProvider = FutureProvider<InstitutionModel?>((ref) async {
  final selectedStudent = ref.watch(selectedStudentProvider);

  if (selectedStudent == null) {
    debugPrint('Institution Provider: No student selected');
    return null;
  }

  debugPrint('Institution Provider: Fetching institution for student "${selectedStudent.name}" with ins_id=${selectedStudent.insId}');
  final client = ref.watch(supabaseClientProvider);

  try {
    // Query institution table matching ins_id from student record
    final response = await client
        .from('institution')
        .select('*')
        .eq('ins_id', selectedStudent.insId)
        .maybeSingle();

    debugPrint('Institution Provider: Response for ins_id=${selectedStudent.insId}: $response');

    if (response != null) {
      final institution = InstitutionModel.fromJson(response);
      debugPrint('Institution Provider: Found institution "${institution.insname}"');
      return institution;
    }

    debugPrint('Institution Provider: No institution found for ins_id=${selectedStudent.insId}');
    return null;
  } catch (e) {
    debugPrint('Institution Provider: Error fetching institution: $e');
    return null;
  }
});
