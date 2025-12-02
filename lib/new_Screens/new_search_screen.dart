import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/screens/change_password_screen.dart';
import 'package:quantum_dashboard/screens/leaves_screen.dart';
import 'package:quantum_dashboard/screens/new_payslip_screen.dart';
import 'package:quantum_dashboard/screens/holidays_screen.dart';
import 'package:quantum_dashboard/new_Screens/settings_page.dart';

class new_search_screen extends StatefulWidget {
  const new_search_screen({super.key});

  @override
  State<new_search_screen> createState() => _new_search_screenState();
}

class _new_search_screenState extends State<new_search_screen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SearchResult> _searchResults = [];
  List<String> _recentSearches = [];
  NavigatorState? _navigator;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  // Define all available services/features in the app
  // Only includes: Leaves, Payslips, Holidays, Change Password
  final List<AppService> _allServices = [
    // Leaves
    AppService(
      id: 'leave_apply',
      title: 'Apply Leave',
      description: 'Request time off or leave',
      category: 'Leaves',
      icon: Icons.event_busy,
      color: Colors.orange,
      keywords: [
        'vacation',
        'time off',
        'absence',
        'request',
        'leave',
        'apply',
      ],
    ),
    AppService(
      id: 'leave_history',
      title: 'Leave History',
      description: 'View your past leave applications',
      category: 'Leaves',
      icon: Icons.history,
      color: Colors.grey,
      keywords: ['past leaves', 'leave records', 'history', 'previous'],
    ),
    // Payslips
    AppService(
      id: 'payslips',
      title: 'Payslips',
      description: 'View and download your payslips',
      category: 'Payslips',
      icon: Icons.receipt_long,
      color: Colors.blue,
      keywords: [
        'salary',
        'pay slip',
        'wages',
        'income',
        'payment',
        'download payslip',
        'payslip',
      ],
    ),
    // Holidays
    AppService(
      id: 'holidays',
      title: 'Holidays',
      description: 'View upcoming holidays and leaves',
      category: 'Holidays',
      icon: Icons.celebration,
      color: Colors.purple,
      keywords: ['vacation', 'off', 'holiday list', 'holidays', 'holiday'],
    ),
    // Change Password
    AppService(
      id: 'change_password',
      title: 'Change Password',
      description: 'Update your account password',
      category: 'Settings',
      icon: Icons.lock,
      color: Colors.cyan,
      keywords: ['password', 'security', 'update password', 'change password'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _allServices
            .where(
              (service) =>
                  service.title.toLowerCase().contains(_searchQuery) ||
                  service.description.toLowerCase().contains(_searchQuery) ||
                  service.category.toLowerCase().contains(_searchQuery) ||
                  service.keywords.any(
                    (keyword) => keyword.contains(_searchQuery),
                  ),
            )
            .map((service) => SearchResult(service: service))
            .toList();
      }
    });
  }

  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  void _handleServiceTap(AppService service) {
    if (!mounted) return;

    _addToRecentSearches(service.title);

    // Handle navigation based on service ID
    switch (service.id) {
      case 'leave_apply':
      case 'leave_history':
        // Navigate to leaves screen for all leave-related services
        if (_navigator != null) {
          _navigator!.push(
            MaterialPageRoute(builder: (context) => LeavesScreen()),
          );
        }
        break;
      case 'holidays':
        if (_navigator != null && mounted) {
          _navigator!.push(
            MaterialPageRoute(builder: (context) => HolidaysScreen()),
          );
        }
        break;
      case 'settings':
        // Navigate to settings page
        if (_navigator != null) {
          _navigator!.push(
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
        }
        break;
      case 'payslips':
        // Navigate to new payslip screen
        if (_navigator != null) {
          _navigator!.push(
            MaterialPageRoute(builder: (context) => NewPayslipScreen()),
          );
        }
        break;
      case 'change_password':
        // Navigate to change password screen
        if (_navigator != null) {
          _navigator!.push(
            MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
          );
        }
        break;
      default:
        _showComingSoonMessage(service);
        break;
    }
  }

  void _showComingSoonMessage(AppService service) {
    if (!mounted || _scaffoldMessenger == null) return;
    _scaffoldMessenger!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(service.icon, color: Colors.white),
            const SizedBox(width: 12),
            Text('Opening ${service.title}...'),
          ],
        ),
        backgroundColor: service.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final categories = _allServices
        .map((service) => service.category)
        .toSet()
        .toList();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.search, size: 24, color: colorScheme.onSurface),
            const SizedBox(width: 12),
            Text(
              'Search Services',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
            onPressed: () {
              if (_navigator != null && mounted) {
                _navigator!.push(
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              }
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      theme.inputDecorationTheme.fillColor ??
                      colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Search for services, features...',
                    hintStyle: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildDefaultView(context, categories, user)
                  : _buildSearchResults(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultView(
    BuildContext context,
    List<String> categories,
    user,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 24),
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader(context, 'Recent Searches', Icons.history),
            const SizedBox(height: 12),
            _buildRecentSearches(context),
            const SizedBox(height: 24),
          ],
          // All Services by Category
          _buildSectionHeader(context, 'All Services', Icons.apps),
          const SizedBox(height: 12),
          ...categories.map(
            (category) => _buildCategorySection(context, category),
          ),
          const SizedBox(height: 120), // Extra padding for nav bar
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final quickActions = [
      _allServices.firstWhere((s) => s.id == 'leave_apply'),
      _allServices.firstWhere((s) => s.id == 'payslips'),
      _allServices.firstWhere((s) => s.id == 'holidays'),
      _allServices.firstWhere((s) => s.id == 'change_password'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Quick Actions', Icons.flash_on),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            return _buildQuickActionCard(quickActions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(AppService service) {
    return GestureDetector(
      onTap: () => _handleServiceTap(service),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [service.color, service.color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: service.color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(service.icon, color: Colors.white, size: 28),
              ),
              Text(
                service.title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_recentSearches.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Recent Searches",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                minimumSize: Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                setState(() {
                  _recentSearches.clear();
                });
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text("Clear"),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((search) {
            return GestureDetector(
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      search,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String category) {
    final services = _allServices.where((s) => s.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        ...services.map((service) => _buildServiceTile(context, service)),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, AppService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.03)),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _handleServiceTap(service),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: service.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(service.icon, color: service.color, size: 24),
        ),
        title: Text(
          service.title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          service.description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_searchResults.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        120,
      ), // Extra bottom padding for nav bar
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultTile(context, result.service);
      },
    );
  }

  Widget _buildSearchResultTile(BuildContext context, AppService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.05)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _handleServiceTap(service),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: service.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(service.icon, color: service.color, size: 28),
        ),
        title: Text(
          service.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              service.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: service.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                service.category,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: service.color,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }
}

class AppService {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  AppService({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

class SearchResult {
  final AppService service;

  SearchResult({required this.service});
}
