import 'package:flutter/material.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/holiday_service.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';

class HolidaysScreen extends StatefulWidget {
  @override
  _HolidaysScreenState createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  final HolidayService _holidayService = HolidayService();
  List<Holiday> _holidays = [];
  List<Holiday> _filteredHolidays = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final holidays = await _holidayService.getHolidays();
      setState(() {
        _holidays = holidays;
        _filteredHolidays = holidays;
        _isLoading = false;
      });
      _filterHolidays();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterHolidays() {
    setState(() {
      _filteredHolidays = _holidays.where((holiday) {
        final matchesYear = holiday.year == _selectedYear;
        final matchesSearch =
            _searchQuery.isEmpty ||
            holiday.holidayName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            holiday.day.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesYear && matchesSearch;
      }).toList();
    });
  }

  Widget _buildYearSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Year: ',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          DropdownButton<int>(
            value: _selectedYear,
            items: List.generate(5, (index) {
              final year = DateTime.now().year - 2 + index;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (int? newYear) {
              if (newYear != null) {
                setState(() {
                  _selectedYear = newYear;
                });
                _filterHolidays();
              }
            },
          ),
          SizedBox(width: 20),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search holidays...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterHolidays();
              },
            ),
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHolidays,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
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
                      holiday.holidayName,
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
                    holiday.date,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Posted by ${holiday.postBy}',
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

  Widget _buildHolidaysList() {
    if (_filteredHolidays.isEmpty) {
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
      itemCount: _filteredHolidays.length,
      itemBuilder: (context, index) {
        return _buildHolidayCard(_filteredHolidays[index]);
      },
    );
  }

  Widget _buildCompactTable() {
    if (_filteredHolidays.isEmpty) {
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
        rows: _filteredHolidays.map((holiday) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  holiday.sNo.toString(),
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  holiday.holidayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Text(
                  holiday.date,
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
                  holiday.postBy,
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
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading holidays...', style: AppTextStyles.body),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading holidays',
                          style: AppTextStyles.body.copyWith(color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHolidays,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : isTablet
                ? _buildCompactTable()
                : _buildHolidaysList(),
          ),
        ],
      ),
    );
  }
}
