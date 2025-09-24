import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'Attendance Summary';
  String _selectedTimeRange = 'This Month';
  String _selectedClass = 'All Classes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          
          // Report Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Header
                  _buildReportHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Report Content based on selection
                  _buildReportContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Report Type Filter
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Attendance Summary',
                    'Student Performance',
                    'Class Statistics',
                    'Attendance Trends',
                    'Detailed Report',
                  ].map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReportType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeRange,
                  decoration: const InputDecoration(
                    labelText: 'Time Range',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'This Week',
                    'This Month',
                    'This Semester',
                    'Last 6 Months',
                    'This Year',
                  ].map((range) => DropdownMenuItem(
                    value: range,
                    child: Text(range),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeRange = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Class Filter
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
            ),
            items: [
              'All Classes',
              'Mathematics',
              'Physics',
              'Chemistry',
              'Computer Science',
              'English',
            ].map((cls) => DropdownMenuItem(
              value: cls,
              child: Text(cls),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClass = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                _selectedReportType,
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Report for $_selectedTimeRange - $_selectedClass',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'Attendance Summary':
        return _buildAttendanceSummary();
      case 'Student Performance':
        return _buildStudentPerformance();
      case 'Class Statistics':
        return _buildClassStatistics();
      case 'Attendance Trends':
        return _buildAttendanceTrends();
      case 'Detailed Report':
        return _buildDetailedReport();
      default:
        return _buildAttendanceSummary();
    }
  }

  Widget _buildAttendanceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Students',
                value: '156',
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Present Today',
                value: '142',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Absent Today',
                value: '14',
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Attendance Chart
        _buildAttendanceChart(),
        
        const SizedBox(height: 20),
        
        // Top Performers
        _buildTopPerformers(),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 85,
                      title: 'Present\n85%',
                      color: Colors.green,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 15,
                      title: 'Absent\n15%',
                      color: Colors.red,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performers',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPerformerItem('John Doe', 'Computer Science', 98.5, 1),
            _buildPerformerItem('Jane Smith', 'Mathematics', 96.2, 2),
            _buildPerformerItem('Mike Johnson', 'Physics', 94.8, 3),
            _buildPerformerItem('Sarah Wilson', 'Chemistry', 93.1, 4),
            _buildPerformerItem('David Brown', 'Computer Science', 91.7, 5),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerItem(String name, String course, double attendance, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  course,
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${attendance}%',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPerformance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Performance Trends',
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: AppTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                              return Text(
                                months[value.toInt() % 6],
                                style: AppTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 75),
                            const FlSpot(1, 80),
                            const FlSpot(2, 85),
                            const FlSpot(3, 88),
                            const FlSpot(4, 90),
                            const FlSpot(5, 92),
                          ],
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Performance Table
        _buildPerformanceTable(),
      ],
    );
  }

  Widget _buildPerformanceTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Performance Details',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DataTable(
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Course')),
                DataColumn(label: Text('Attendance')),
                DataColumn(label: Text('Grade')),
              ],
              rows: [
                _buildDataRow('John Doe', 'Computer Science', '98.5%', 'A+'),
                _buildDataRow('Jane Smith', 'Mathematics', '96.2%', 'A'),
                _buildDataRow('Mike Johnson', 'Physics', '94.8%', 'A'),
                _buildDataRow('Sarah Wilson', 'Chemistry', '93.1%', 'A-'),
                _buildDataRow('David Brown', 'Computer Science', '91.7%', 'B+'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(String student, String course, String attendance, String grade) {
    return DataRow(
      cells: [
        DataCell(Text(student)),
        DataCell(Text(course)),
        DataCell(Text(attendance)),
        DataCell(Text(grade)),
      ],
    );
  }

  Widget _buildClassStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Classes',
                value: '24',
                icon: Icons.class_,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Completed',
                value: '20',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Pending',
                value: '4',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Class Performance Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Performance',
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const classes = ['Math', 'Physics', 'Chem', 'CS', 'Eng'];
                              return Text(
                                classes[value.toInt() % 5],
                                style: AppTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: AppTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 85, color: Colors.blue)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 90, color: Colors.green)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 75, color: Colors.orange)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 88, color: Colors.purple)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 92, color: Colors.teal)]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Trends',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: AppTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Text(
                            days[value.toInt() % 7],
                            style: AppTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 80),
                        const FlSpot(1, 85),
                        const FlSpot(2, 90),
                        const FlSpot(3, 75),
                        const FlSpot(4, 88),
                        const FlSpot(5, 92),
                        const FlSpot(6, 85),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detailed Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Statistics',
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Students', '156'),
                _buildStatRow('Present Students', '142'),
                _buildStatRow('Absent Students', '14'),
                _buildStatRow('Average Attendance', '91.0%'),
                _buildStatRow('Best Performing Class', 'Computer Science (95.2%)'),
                _buildStatRow('Needs Attention', 'Physics (78.5%)'),
                _buildStatRow('Total Classes Conducted', '24'),
                _buildStatRow('Classes Remaining', '4'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Recommendations
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendations',
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildRecommendationItem(
                  'Improve Physics Class Attendance',
                  'Consider interactive teaching methods to increase engagement',
                  Icons.lightbulb,
                  Colors.orange,
                ),
                _buildRecommendationItem(
                  'Follow up with Absent Students',
                  'Contact 14 students who were absent today',
                  Icons.phone,
                  Colors.blue,
                ),
                _buildRecommendationItem(
                  'Maintain Computer Science Performance',
                  'Continue current teaching approach for best results',
                  Icons.star,
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyLarge,
          ),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report exported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
