import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/compoff_credit_model.dart';
import 'package:quantum_dashboard/providers/compoff_provider.dart';

class CompoffWalletScreen extends StatefulWidget {
  const CompoffWalletScreen({super.key});

  @override
  State<CompoffWalletScreen> createState() => _CompoffWalletScreenState();
}

class _CompoffWalletScreenState extends State<CompoffWalletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const int warningDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CompoffProvider>(context, listen: false).fetchMyCredits();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<CompoffProvider>(context, listen: false).fetchMyCredits();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Compoff Wallet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.onPrimary,
              indicatorWeight: 3,
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'Available'),
                Tab(text: 'Used'),
                Tab(text: 'Expired'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<CompoffProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.credits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading your compoff credits...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final available = provider.credits
              .where((c) => c.status == 'AVAILABLE')
              .toList();
          final used = provider.credits
              .where((c) => c.status == 'USED')
              .toList();
          final expired = provider.credits
              .where((c) => c.status == 'EXPIRED')
              .toList();

          return Column(
            children: [
              // Summary chips
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface,
                child: Row(
                  children: [
                    _buildSummaryChip(
                      context,
                      count: available.length,
                      label: 'Available',
                      color: colorScheme.primary,
                      icon: Icons.check_circle_outline,
                    ),
                    SizedBox(width: 10),
                    _buildSummaryChip(
                      context,
                      count: used.length,
                      label: 'Used',
                      color: colorScheme.tertiary,
                      icon: Icons.history,
                    ),
                    SizedBox(width: 10),
                    _buildSummaryChip(
                      context,
                      count: expired.length,
                      label: 'Expired',
                      color: colorScheme.error,
                      icon: Icons.schedule,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreditList(
                      context,
                      available,
                      emptyText: 'No available compoff credits',
                      emptySubtext: 'Credits earned on holidays or weekly offs will appear here.',
                      showWarning: true,
                    ),
                    _buildCreditList(
                      context,
                      used,
                      emptyText: 'No used compoff credits',
                      emptySubtext: 'Credits you\'ve applied to leave will show here.',
                    ),
                    _buildCreditList(
                      context,
                      expired,
                      emptyText: 'No expired compoff credits',
                      emptySubtext: 'Expired credits will be listed here.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditList(
    BuildContext context,
    List<CompoffCredit> credits, {
    required String emptyText,
    String emptySubtext = '',
    bool showWarning = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (credits.isEmpty) {
      return _buildEmptyState(
        colorScheme: colorScheme,
        emptyText: emptyText,
        emptySubtext: emptySubtext,
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: credits.length,
        itemBuilder: (context, index) {
          final credit = credits[index];
          final daysLeft = credit.expiryDate.difference(DateTime.now()).inDays;
          final isWarning =
              showWarning && daysLeft >= 0 && daysLeft <= warningDays;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isWarning
                  ? BorderSide(color: colorScheme.tertiary, width: 1.5)
                  : BorderSide.none,
            ),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_available,
                          color: colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              credit.earnedSource.replaceAll('_', ' '),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Earned ${DateFormat('dd MMM yyyy').format(credit.earnedDate)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(
                          context, credit.status, isWarning),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Expires ${DateFormat('dd MMM yyyy').format(credit.expiryDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  if (isWarning) ...[
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: colorScheme.tertiary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Expiring in $daysLeft day(s)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required ColorScheme colorScheme,
    required String emptyText,
    required String emptySubtext,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: colorScheme.onSurface.withOpacity(0.35),
            ),
            SizedBox(height: 20),
            Text(
              emptyText,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.85),
              ),
              textAlign: TextAlign.center,
            ),
            if (emptySubtext.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                emptySubtext,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status, bool isWarning) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label = status;

    switch (status) {
      case 'AVAILABLE':
        color = isWarning ? colorScheme.tertiary : colorScheme.primary;
        label = isWarning ? 'Expiring soon' : 'Available';
        break;
      case 'USED':
        color = colorScheme.tertiary;
        label = 'Used';
        break;
      case 'EXPIRED':
        color = colorScheme.error;
        label = 'Expired';
        break;
      default:
        color = colorScheme.outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
