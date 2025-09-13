import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';

class HolidaysScreen extends StatefulWidget {
  @override
  _HolidaysScreenState createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HolidayProvider>(context, listen: false).getHolidays();
    });
  }

  Widget _buildHolidayCard(Holiday holiday) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CustomFloatingContainer(
        // margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      holiday.title,
                      style: AppTextStyles.subheading.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      holiday.day,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    // Format the DateTime to a readable string
                    "${holiday.date.day.toString().padLeft(2, '0')}-${holiday.date.month.toString().padLeft(2, '0')}-${holiday.date.year}",
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  Spacer(),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Posted by ${holiday.action}',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHolidaysList(List<Holiday> filteredHolidays) {
    if (filteredHolidays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No holidays found for $_selectedYear'
                  : 'No holidays match your search',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredHolidays.length,
      itemBuilder: (context, index) {
        return _buildHolidayCard(filteredHolidays[index]);
      },
    );
  }

  Widget _buildCompactTable(List<Holiday> filteredHolidays) {
    if (filteredHolidays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No holidays found for $_selectedYear'
                  : 'No holidays match your search',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 8,
        dataRowHeight: 60,
        headingRowHeight: 50,
        columns: [
          DataColumn(
            label: Text(
              'S.No',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Holiday',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Date',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Day',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'By',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
        rows: filteredHolidays.map((holiday) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  holiday.id.toString(),
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  holiday.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Text(
                  holiday.formattedDate,
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    holiday.day.substring(0, 3),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  holiday.action,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 12),
          // _buildYearSelector(),
          Expanded(
            child: Consumer<HolidayProvider>(
              builder: (context, holidayProvider, child) {
                // Compute filtered holidays without calling setState
                final filteredHolidays = holidayProvider.holidays.where((
                  holiday,
                ) {
                  final matchesYear = holiday.year == _selectedYear;
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      holiday.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      holiday.day.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                  return matchesYear && matchesSearch;
                }).toList();

                return holidayProvider.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading holidays...',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      )
                    : holidayProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading holidays',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              holidayProvider.error!,
                              style: AppTextStyles.body.copyWith(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                holidayProvider.getHolidays();
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : isTablet
                    ? _buildCompactTable(filteredHolidays)
                    : _buildHolidaysList(filteredHolidays);
              },
            ),
          ),
        ],
      ),
    );
  }
}
