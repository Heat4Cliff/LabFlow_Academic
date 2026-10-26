class LabAdminProfile {
  const LabAdminProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.laboratories,
  });

  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final List<LabAdminProfileLaboratory> laboratories;

  String get displayName =>
      fullName.trim().isEmpty ? 'Lab Admin' : fullName.trim();

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'LA';
    }

    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class LabAdminProfileLaboratory {
  const LabAdminProfileLaboratory({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
  });

  final String id;
  final String code;
  final String name;
  final String location;
}
