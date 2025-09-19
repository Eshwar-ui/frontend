class Employee {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final DateTime dateOfBirth;
  final DateTime joiningDate;
  final String password;
  final String profileImage;
  final String? department;
  final String? designation;
  final String? gender;
  final String? grade;
  final String? role;
  final String? report;
  final String? address;
  final String? bankname;
  final String? accountnumber;
  final String? ifsccode;
  final String? PANno;
  final String? UANno;
  final String? ESIno;
  final String? fathername;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.dateOfBirth,
    required this.joiningDate,
    required this.password,
    required this.profileImage,
    this.department,
    this.designation,
    this.gender,
    this.grade,
    this.role,
    this.report,
    this.address,
    this.bankname,
    this.accountnumber,
    this.ifsccode,
    this.PANno,
    this.UANno,
    this.ESIno,
    this.fathername,
  });

  Employee copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    DateTime? dateOfBirth,
    DateTime? joiningDate,
    String? password,
    String? profileImage,
    String? department,
    String? designation,
    String? gender,
    String? grade,
    String? role,
    String? report,
    String? address,
    String? bankname,
    String? accountnumber,
    String? ifsccode,
    String? PANno,
    String? UANno,
    String? ESIno,
    String? fathername,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      joiningDate: joiningDate ?? this.joiningDate,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      gender: gender ?? this.gender,
      grade: grade ?? this.grade,
      role: role ?? this.role,
      report: report ?? this.report,
      address: address ?? this.address,
      bankname: bankname ?? this.bankname,
      accountnumber: accountnumber ?? this.accountnumber,
      ifsccode: ifsccode ?? this.ifsccode,
      PANno: PANno ?? this.PANno,
      UANno: UANno ?? this.UANno,
      ESIno: ESIno ?? this.ESIno,
      fathername: fathername ?? this.fathername,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and '_id' field names
    final id = json['id'] as String? ?? json['_id'] as String?;
    final employeeId = json['employeeId'] as String?;
    final firstName = json['firstName'] as String?;
    final lastName = json['lastName'] as String?;
    final email = json['email'] as String?;
    final mobile = json['mobile'] as String?;
    final dateOfBirthString = json['dateOfBirth'] as String?;
    final joiningDateString = json['joiningDate'] as String?;
    final password = json['password'] as String?;
    final profileImage = json['profileImage'] as String?;
    final department = json['department'] as String?;
    final designation = json['designation'] as String?;
    final gender = json['gender'] as String?;
    final grade = json['grade'] as String?;
    final role = json['role'] as String?;
    final report = json['report'] as String?;
    final address = json['address'] as String?;
    final bankname = json['bankname'] as String?;
    final accountnumber = json['accountnumber'] as String?;
    final ifsccode = json['ifsccode'] as String?;
    final PANno = json['PANno'] as String?;
    final UANno = json['UANno'] as String?;
    final ESIno = json['ESIno'] as String?;
    final fathername = json['fathername'] as String?;

    return Employee(
      id: id ?? '',
      employeeId: employeeId ?? '',
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      email: email ?? '',
      mobile: mobile ?? '',
      dateOfBirth: dateOfBirthString != null
          ? _parseDate(dateOfBirthString)
          : DateTime.now(),
      joiningDate: joiningDateString != null
          ? _parseDate(joiningDateString)
          : DateTime.now(),
      password: password ?? '',
      profileImage: profileImage ?? '',
      department: department,
      designation: designation,
      gender: gender,
      grade: grade,
      role: role,
      report: report,
      address: address,
      bankname: bankname,
      accountnumber: accountnumber,
      ifsccode: ifsccode,
      PANno: PANno,
      UANno: UANno,
      ESIno: ESIno,
      fathername: fathername,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'joiningDate': joiningDate.toIso8601String(),
      'password': password,
      'profileImage': profileImage,
      'department': department,
      'designation': designation,
      'gender': gender,
      'grade': grade,
      'role': role,
      'report': report,
      'address': address,
      'bankname': bankname,
      'accountnumber': accountnumber,
      'ifsccode': ifsccode,
      'PANno': PANno,
      'UANno': UANno,
      'ESIno': ESIno,
      'fathername': fathername,
    };
  }

  String get fullName => '$firstName $lastName';

  // Helper method to parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    print(
      'UserModel: Parsing date value: $dateValue (type: ${dateValue.runtimeType})',
    );
    try {
      // If it's already a DateTime object, return it
      if (dateValue is DateTime) {
        print('UserModel: Date is already DateTime, returning as-is');
        return dateValue;
      }

      // If it's a String, try to parse it
      if (dateValue is String) {
        print('UserModel: Date is String, attempting to parse');
        // Try parsing as ISO format first (for backward compatibility)
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // If ISO parsing fails, try parsing "dd-MM-yyyy" format
          try {
            final parts = dateValue.split('-');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } catch (e) {
            print(
              'Error parsing date string: $dateValue, using current date as fallback',
            );
            return DateTime.now();
          }
        }
      }

      // If it's neither DateTime nor String, return current date
      print(
        'Unexpected date type: ${dateValue.runtimeType}, using current date as fallback',
      );
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $dateValue, using current date as fallback');
      return DateTime.now();
    }
  }
}
