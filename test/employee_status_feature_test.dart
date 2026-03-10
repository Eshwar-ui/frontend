import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_dashboard_screen.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/screens/add_employee_screen.dart';
import 'package:quantum_dashboard/screens/admin_employees_screen.dart';
import 'package:quantum_dashboard/screens/edit_employee_screen.dart';

class _TestEmployeeProvider extends EmployeeProvider {
  _TestEmployeeProvider({
    List<Employee> seedEmployees = const [],
    this.employeesAfterFetch,
  }) : _employees = List<Employee>.from(seedEmployees);

  List<Employee> _employees;
  final List<Employee>? employeesAfterFetch;
  Map<String, dynamic>? lastAddedPayload;
  Map<String, dynamic>? lastUpdatedPayload;
  String? lastUpdatedId;
  int getAllEmployeesCallCount = 0;

  @override
  List<Employee> get employees => _employees;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> getAllEmployees({
    String? employeeId,
    String? employeeName,
    String? designation,
    String? status,
  }) async {
    getAllEmployeesCallCount++;
    if (_employees.isEmpty && employeesAfterFetch != null) {
      _employees = List<Employee>.from(employeesAfterFetch!);
      notifyListeners();
    }
  }

  @override
  Future<Map<String, dynamic>> addEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    lastAddedPayload = Map<String, dynamic>.from(employeeData);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> updates,
  ) async {
    lastUpdatedId = id;
    lastUpdatedPayload = Map<String, dynamic>.from(updates);
    return {'success': true};
  }
}

class _TestLeaveProvider extends LeaveProvider {
  _TestLeaveProvider({this.seedLeaves = const []});

  final List<Leave> seedLeaves;

  @override
  List<Leave> get leaves => seedLeaves;

  @override
  Future<void> getAllLeaves() async {}
}

Finder _fieldByHint(String hint) {
  return find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == hint,
  );
}

Employee _buildEmployee({
  required String id,
  required String employeeId,
  required String firstName,
  required String status,
}) {
  return Employee(
    id: id,
    employeeId: employeeId,
    firstName: firstName,
    lastName: 'User',
    email: '$firstName@example.com',
    mobile: '9999999999',
    dateOfBirth: DateTime(1990, 1, 1),
    joiningDate: DateTime(2023, 1, 1),
    password: '',
    profileImage: '',
    designation: 'Engineer',
    role: 'employee',
    status: status,
  );
}

void main() {
  group('Employee status model', () {
    test('falls back to active for missing/invalid status', () {
      final missing = Employee.fromJson({
        '_id': '1',
        'employeeId': 'QWIT-1001',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a@b.com',
        'mobile': '1',
        'dateOfBirth': '2020-01-01T00:00:00.000Z',
        'joiningDate': '2020-01-01T00:00:00.000Z',
        'password': '',
        'profileImage': '',
      });
      final invalid = Employee.fromJson({
        '_id': '2',
        'employeeId': 'QWIT-1002',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a2@b.com',
        'mobile': '1',
        'dateOfBirth': '2020-01-01T00:00:00.000Z',
        'joiningDate': '2020-01-01T00:00:00.000Z',
        'password': '',
        'profileImage': '',
        'status': 'pending',
      });

      expect(missing.status, 'active');
      expect(invalid.status, 'active');
    });

    test('normalizes valid status from JSON', () {
      final employee = Employee.fromJson({
        '_id': '3',
        'employeeId': 'QWIT-1003',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a3@b.com',
        'mobile': '1',
        'dateOfBirth': '2020-01-01T00:00:00.000Z',
        'joiningDate': '2020-01-01T00:00:00.000Z',
        'password': '',
        'profileImage': '',
        'status': 'HoLd',
      });

      expect(employee.status, 'hold');
    });
  });

  group('Employee status UI', () {
    testWidgets('add employee submits selected status', (tester) async {
      final provider = _TestEmployeeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<EmployeeProvider>.value(
          value: provider,
          child: MaterialApp(home: AddEmployeeScreen(onEmployeeAdded: () {})),
        ),
      );

      await tester.enterText(_fieldByHint('John'), 'John');
      await tester.enterText(_fieldByHint('Doe'), 'Doe');
      await tester.enterText(
        _fieldByHint('john.doe@example.com'),
        'john.doe@example.com',
      );
      await tester.enterText(_fieldByHint('Enter login password'), 'password1');
      await tester.enterText(_fieldByHint('+91 9876543210'), '9876543210');
      await tester.enterText(_fieldByHint('QWIT-1001'), 'QWIT-2001');

      final formScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Status'),
        300,
        scrollable: formScroll,
      );
      await tester.tap(find.text('ACTIVE').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('TERMINATED').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save').first);
      await tester.pumpAndSettle();

      expect(provider.lastAddedPayload, isNotNull);
      expect(provider.lastAddedPayload!['status'], 'terminated');
    });

    testWidgets('edit employee submits selected status', (tester) async {
      final provider = _TestEmployeeProvider();
      final employee = _buildEmployee(
        id: 'mongo-id-1',
        employeeId: 'QWIT-2002',
        firstName: 'Edit',
        status: 'active',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<EmployeeProvider>.value(
          value: provider,
          child: MaterialApp(
            home: EditEmployeeScreen(
              employee: employee,
              onEmployeeUpdated: () {},
            ),
          ),
        ),
      );

      final formScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Status'),
        300,
        scrollable: formScroll,
      );
      await tester.tap(find.text('ACTIVE').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('TERMINATED').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save').first);
      await tester.pumpAndSettle();

      expect(provider.lastUpdatedId, 'mongo-id-1');
      expect(provider.lastUpdatedPayload, isNotNull);
      expect(provider.lastUpdatedPayload!['status'], 'terminated');
    });

    testWidgets('admin employee list shows badges and filters by status', (
      tester,
    ) async {
      final authProvider = AuthProvider();
      final navigationProvider = NavigationProvider();
      authProvider.setUser(
        _buildEmployee(
          id: 'admin-id',
          employeeId: 'QWIT-1001',
          firstName: 'Admin',
          status: 'active',
        ).copyWith(role: 'admin'),
      );

      final employeeProvider = _TestEmployeeProvider(
        seedEmployees: [
          _buildEmployee(
            id: '1',
            employeeId: 'QWIT-2010',
            firstName: 'Active',
            status: 'active',
          ),
          _buildEmployee(
            id: '2',
            employeeId: 'QWIT-2011',
            firstName: 'Hold',
            status: 'hold',
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<EmployeeProvider>.value(
              value: employeeProvider,
            ),
            ChangeNotifierProvider<NavigationProvider>.value(
              value: navigationProvider,
            ),
          ],
          child: MaterialApp(home: Scaffold(body: AdminEmployeesScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Hold'), findsOneWidget);
      expect(find.text('Active User'), findsOneWidget);
      expect(find.text('Hold User'), findsOneWidget);

      await tester.ensureVisible(find.text('All Statuses'));
      await tester.tap(find.text('All Statuses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminated').last);
      await tester.pumpAndSettle();

      expect(find.text('Active User'), findsNothing);
      expect(find.text('Hold User'), findsNothing);
    });

    testWidgets('dashboard popup navigates with pending status filter', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(120000, 2000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authProvider = AuthProvider();
      final employeeProvider = _TestEmployeeProvider(
        seedEmployees: [
          _buildEmployee(
            id: '1',
            employeeId: 'QWIT-3001',
            firstName: 'Active',
            status: 'active',
          ),
          _buildEmployee(
            id: '2',
            employeeId: 'QWIT-3002',
            firstName: 'Hold',
            status: 'hold',
          ),
          _buildEmployee(
            id: '3',
            employeeId: 'QWIT-3003',
            firstName: 'HoldTwo',
            status: 'hold',
          ),
          _buildEmployee(
            id: '4',
            employeeId: 'QWIT-3004',
            firstName: 'Inactive',
            status: 'inactive',
          ),
        ],
      );
      final leaveProvider = _TestLeaveProvider();
      final navigationProvider = NavigationProvider();
      final notificationProvider = NotificationProvider();
      authProvider.setUser(
        _buildEmployee(
          id: 'admin-id',
          employeeId: 'QWIT-1001',
          firstName: 'Admin',
          status: 'active',
        ).copyWith(role: 'admin'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<EmployeeProvider>.value(
              value: employeeProvider,
            ),
            ChangeNotifierProvider<LeaveProvider>.value(value: leaveProvider),
            ChangeNotifierProvider<NavigationProvider>.value(
              value: navigationProvider,
            ),
            ChangeNotifierProvider<NotificationProvider>.value(
              value: notificationProvider,
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('total-employees-stat-card')));
      await tester.pumpAndSettle();

      expect(find.text('Employee Status Overview'), findsOneWidget);
      expect(find.text('Total Employees: 4'), findsOneWidget);
      expect(
        find.byKey(const Key('employee-status-count-hold')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('employee-status-row-hold')));
      await tester.pumpAndSettle();

      expect(navigationProvider.currentPage, NavigationPage.AdminEmployees);
      expect(navigationProvider.pendingAdminEmployeeStatusFilter, 'hold');
    });

    testWidgets('dashboard fetches employees before opening popup when empty', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(120000, 2000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authProvider = AuthProvider();
      final employeeProvider = _TestEmployeeProvider(
        seedEmployees: const [],
        employeesAfterFetch: [
          _buildEmployee(
            id: '9',
            employeeId: 'QWIT-3999',
            firstName: 'Terminated',
            status: 'terminated',
          ),
        ],
      );
      final leaveProvider = _TestLeaveProvider();
      final navigationProvider = NavigationProvider();
      final notificationProvider = NotificationProvider();
      authProvider.setUser(
        _buildEmployee(
          id: 'admin-id',
          employeeId: 'QWIT-1001',
          firstName: 'Admin',
          status: 'active',
        ).copyWith(role: 'admin'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<EmployeeProvider>.value(
              value: employeeProvider,
            ),
            ChangeNotifierProvider<LeaveProvider>.value(value: leaveProvider),
            ChangeNotifierProvider<NavigationProvider>.value(
              value: navigationProvider,
            ),
            ChangeNotifierProvider<NotificationProvider>.value(
              value: notificationProvider,
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('total-employees-stat-card')));
      await tester.pumpAndSettle();

      expect(
        employeeProvider.getAllEmployeesCallCount,
        greaterThanOrEqualTo(1),
      );
      expect(find.text('Total Employees: 1'), findsOneWidget);
    });

    testWidgets('admin employees consumes pending status filter once', (
      tester,
    ) async {
      final authProvider = AuthProvider();
      final navigationProvider = NavigationProvider();
      navigationProvider.setPendingAdminEmployeeStatusFilter('hold');
      authProvider.setUser(
        _buildEmployee(
          id: 'admin-id',
          employeeId: 'QWIT-1001',
          firstName: 'Admin',
          status: 'active',
        ).copyWith(role: 'admin'),
      );
      final employeeProvider = _TestEmployeeProvider(
        seedEmployees: [
          _buildEmployee(
            id: '1',
            employeeId: 'QWIT-2010',
            firstName: 'Active',
            status: 'active',
          ),
          _buildEmployee(
            id: '2',
            employeeId: 'QWIT-2011',
            firstName: 'Hold',
            status: 'hold',
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<EmployeeProvider>.value(
              value: employeeProvider,
            ),
            ChangeNotifierProvider<NavigationProvider>.value(
              value: navigationProvider,
            ),
          ],
          child: MaterialApp(home: Scaffold(body: AdminEmployeesScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hold User'), findsOneWidget);
      expect(find.text('Active User'), findsNothing);
      expect(navigationProvider.pendingAdminEmployeeStatusFilter, isNull);
    });
  });
}
