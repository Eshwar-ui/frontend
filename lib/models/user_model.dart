class Employee {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String department;
  final String designation;
  final DateTime joinDate;
  final double salary;
  final String phone;
  final String address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePhoto;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.department,
    required this.designation,
    required this.joinDate,
    required this.salary,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profilePhoto,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError('json must not be null');
    }

    // Handle both 'id' and '_id' field names
    final id = json['id'] as String? ?? json['_id'] as String?;
    final employeeId = json['employeeId'] as String?;
    final firstName = json['firstName'] as String?;
    final lastName = json['lastName'] as String?;
    final email = json['email'] as String?;
    final role = json['role'] as String?;
    final department = json['department'] as String?;
    final designation = json['designation'] as String?;
    final joinDateString = json['joinDate'] as String?;
    final salary = json['salary'] as num?;
    final phone = json['phone'] as String?;
    final address = json['address'] as String?;
    final isActive = json['isActive'] as bool?;
    final createdAtString = json['createdAt'] as String?;
    final updatedAtString = json['updatedAt'] as String?;
    final profilePhoto = json['profilePhoto'] as String?;

    // Provide default values for missing required fields
    return Employee(
      id: id ?? '',
      employeeId: employeeId ?? '',
      firstName: firstName ?? 'Unknown',
      lastName: lastName ?? 'Employee',
      email: email ?? '',
      role: role ?? 'employee',
      department: department ?? 'Unknown',
      designation: designation ?? 'Unknown',
      joinDate: joinDateString != null 
          ? DateTime.parse(joinDateString) 
          : DateTime.now(),
      salary: salary?.toDouble() ?? 0.0,
      phone: phone ?? '',
      address: address ?? '',
      isActive: isActive ?? true,
      createdAt: createdAtString != null
          ? DateTime.parse(createdAtString)
          : DateTime.now(),
      updatedAt: updatedAtString != null
          ? DateTime.parse(updatedAtString)
          : DateTime.now(),
      profilePhoto: profilePhoto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'department': department,
      'designation': designation,
      'joinDate': joinDate.toIso8601String(),
      'salary': salary,
      'phone': phone,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profilePhoto': profilePhoto,
    };
  }

  String get fullName => '$firstName $lastName';
}
