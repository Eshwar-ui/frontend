class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';

  // Attendance
  static const String punchIn = '/api/punchin';
  static const String punchOut = '/api/punchout';
  static String getPunches(String employeeId) => '/api/punches/$employeeId';
  static String getEmployeeDatePunches(String employeeId, String date) =>
      '/api/admin/employee/date-punches/$employeeId/$date';
  static String getDateWiseData(String employeeId) =>
      '/api/date-wise-data/$employeeId';
  static const String getAdminAttendance = '/api/admin/attendance';

  // Leaves
  static const String applyLeave = '/api/apply-leave';
  static const String updateLeaveStatus = '/api/leave/update-status';
  static String getEmployeeLeaves(String employeeId) =>
      '/api/get-leaves/$employeeId';
  static const String getAllLeaves = '/api/all-leaves';
  static String updateLeave(String employeeId, String leaveId) =>
      '/api/update-leave/$employeeId/$leaveId';
  static String getSpecificLeave(String employeeId, String leaveId) =>
      '/api/get-leave/$employeeId/$leaveId';
  static String deleteLeave(String employeeId, String leaveId) =>
      '/api/delete-leave/$employeeId/$leaveId';

  // Holidays
  static const String addHoliday = '/api/add-holiday';
  static const String getHolidays = '/api/get-holidays';
  static String updateHoliday(String id) => '/api/update-holiday/$id';
  static String deleteHoliday(String id) => '/api/delete-holiday/$id';

  // Employees
  static const String addEmployee = '/api/add-employee';
  static const String getAllEmployees = '/api/all-employees';
  static String getIndividualEmployee(String employeeId) =>
      '/api/individualemployee/$employeeId';
  static String updateEmployee(String id) => '/api/update-employee/$id';
  static String deleteEmployee(String employeeId) =>
      '/api/delete-employee/$employeeId';
  static String changePassword(String employeeId) =>
      '/api/changepassword/$employeeId';

  // Payslips (Generated)
  static const String generatePayslip = '/api/generate-payslip';
  static const String getPayslips = '/api/payslips';
  static String deletePayslip(String payslipId) =>
      '/api/delete-payslip/$payslipId';

  // Payslips (Employee Uploaded)
  static const String uploadPayslip = '/api/upload-payslip/';
  static String getEmployeePayslips(String employeeId) =>
      '/api/employee-payslip/$employeeId';
  static String deleteEmployeePayslip(String payslipId) =>
      '/api/delete-employeepayslip/$payslipId';

  // Departments
  static const String addDepartment = '/api/department';
  static const String getDepartments = '/api/getDepartment';

  // Leave Types
  static const String addLeaveType = '/api/leaveType';
  static const String getLeaveTypes = '/api/getLeavetype';

  // Helper Methods
  static String getFullUrl(String endpoint, {String? baseUrl}) {
    final String base = baseUrl ?? 'http://192.168.1.19:4444';
    return '$base$endpoint';
  }

  static Map<String, String> getAuthHeaders(String? token) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, String> buildQueryParams({
    String? employeeId,
    String? month,
    String? year,
    String? fromDate,
    String? employeeName,
    String? designation,
  }) {
    final params = <String, String>{};
    if (employeeId != null) params['empId'] = employeeId;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    if (fromDate != null) params['fromDate'] = fromDate;
    if (employeeName != null) params['employeeName'] = employeeName;
    if (designation != null) params['designation'] = designation;
    return params;
  }
}
