import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ViewClassesScreen extends StatefulWidget {
  const ViewClassesScreen({super.key});

  @override
  State<ViewClassesScreen> createState() => _ViewClassesScreenState();
}

class _ViewClassesScreenState extends State<ViewClassesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedView = 'Grid';
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    // Mock data - in real app, this would come from API
    _classes = [
      {
        'id': '1',
        'name': 'Mathematics - Calculus',
        'code': 'MATH101',
        'room': 'Room 101',
        'schedule': 'Mon, Wed, Fri 10:00-11:00',
        'teacher': 'Dr. John Smith',
        'students': 45,
        'status': 'Active',
        'startDate': '2024-09-01',
        'endDate': '2024-12-15',
        'description': 'Introduction to Calculus and its applications',
        'attendance': 87.5,
        'nextClass': '2024-09-23 10:00',
        'color': Colors.blue,
      },
      {
        'id': '2',
        'name': 'Physics - Mechanics',
        'code': 'PHYS201',
        'room': 'Room 205',
        'schedule': 'Tue, Thu 2:00-3:30',
        'teacher': 'Dr. Jane Doe',
        'students': 38,
        'status': 'Active',
        'startDate': '2024-09-01',
        'endDate': '2024-12-15',
        'description': 'Classical mechanics and dynamics',
        'attendance': 92.3,
        'nextClass': '2024-09-24 14:00',
        'color': Colors.green,
      },
      {
        'id': '3',
        'name': 'Chemistry - Organic',
        'code': 'CHEM301',
        'room': 'Lab 3',
        'schedule': 'Mon, Wed 9:00-10:30',
        'teacher': 'Dr. Mike Johnson',
        'students': 32,
        'status': 'Active',
        'startDate': '2024-09-01',
        'endDate': '2024-12-15',
        'description': 'Organic chemistry principles and reactions',
        'attendance': 78.9,
        'nextClass': '2024-09-23 09:00',
        'color': Colors.orange,
      },
      {
        'id': '4',
        'name': 'Computer Science - Data Structures',
        'code': 'CS401',
        'room': 'Lab 1',
        'schedule': 'Tue, Thu, Fri 11:00-12:00',
        'teacher': 'Dr. Sarah Wilson',
        'students': 28,
        'status': 'Active',
        'startDate': '2024-09-01',
        'endDate': '2024-12-15',
        'description': 'Data structures and algorithms',
        'attendance': 95.2,
        'nextClass': '2024-09-24 11:00',
        'color': Colors.purple,
      },
      {
        'id': '5',
        'name': 'English - Literature',
        'code': 'ENG101',
        'room': 'Room 150',
        'schedule': 'Mon, Wed 1:00-2:00',
        'teacher': 'Dr. David Brown',
        'students': 42,
        'status': 'Inactive',
        'startDate': '2024-09-01',
        'endDate': '2024-12-15',
        'description': 'Introduction to English literature',
        'attendance': 82.1,
        'nextClass': '2024-09-25 13:00',
        'color': Colors.teal,
      },
      {
        'id': '6',
        'name': 'Biology - Cell Biology',
        'code': 'BIO201',
        'room': 'Lab 2',
        'schedule': 'Tue, Thu 10:00-11:30',
        'teacher': 'Dr. Lisa Garcia',
        'students': 35,
        'status': 'Active',
        'startDate': '2024-09-01',
        'endDate': '2024-12-15',
        'description': 'Study of cell structure and function',
        'attendance': 89.7,
        'nextClass': '2024-09-24 10:00',
        'color': Colors.red,
      },
    ];
    _filteredClasses = List.from(_classes);
  }

  void _filterClasses() {
    setState(() {
      _filteredClasses = _classes.where((cls) {
        final matchesSearch = cls['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            cls['code'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            cls['teacher'].toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesFilter = _selectedFilter == 'All' || cls['status'] == _selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Classes'),
        actions: [
          IconButton(
            icon: Icon(_selectedView == 'Grid' ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _selectedView = _selectedView == 'Grid' ? 'List' : 'Grid';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search classes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterClasses();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _filterClasses(),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Inactive'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            _filterClasses();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Classes List/Grid
          Expanded(
            child: _filteredClasses.isEmpty
                ? _buildEmptyState()
                : _selectedView == 'Grid'
                    ? _buildGridView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No classes found',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredClasses.length,
      itemBuilder: (context, index) {
        final cls = _filteredClasses[index];
        return _buildClassGridCard(cls);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredClasses.length,
      itemBuilder: (context, index) {
        final cls = _filteredClasses[index];
        return _buildClassListCard(cls);
      },
    );
  }

  Widget _buildClassGridCard(Map<String, dynamic> cls) {
    return Card(
      child: InkWell(
        onTap: () => _viewClassDetails(cls),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cls['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.class_,
                      color: cls['color'],
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cls['status'] == 'Active' 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cls['status'],
                      style: AppTheme.labelSmall.copyWith(
                        color: cls['status'] == 'Active' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Class Info
              Text(
                cls['name'],
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                cls['code'],
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              // Stats
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${cls['students']}', style: AppTheme.bodySmall),
                  const Spacer(),
                  Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${cls['attendance']}%', style: AppTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              // Teacher
              Text(
                'Teacher: ${cls['teacher']}',
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassListCard(Map<String, dynamic> cls) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewClassDetails(cls),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Class Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cls['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_,
                  color: cls['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Class Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cls['name'],
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cls['status'] == 'Active' 
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cls['status'],
                            style: AppTheme.labelSmall.copyWith(
                              color: cls['status'] == 'Active' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cls['code'],
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.room, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(cls['room'], style: AppTheme.bodySmall),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${cls['students']}', style: AppTheme.bodySmall),
                        const SizedBox(width: 16),
                        Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${cls['attendance']}%', style: AppTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teacher: ${cls['teacher']}',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewClassDetails(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) => _ClassDetailsDialog(classData: cls),
    );
  }
}

class _ClassDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassDetailsDialog({required this.classData});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: classData['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: classData['color'],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['name'],
                        style: AppTheme.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        classData['code'],
                        style: AppTheme.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: classData['status'] == 'Active' 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classData['status'],
                    style: AppTheme.titleMedium.copyWith(
                      color: classData['status'] == 'Active' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Class Information
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(context, 'Class Information', [
                      _buildInfoRow('Room', classData['room']),
                      _buildInfoRow('Schedule', classData['schedule']),
                      _buildInfoRow('Teacher', classData['teacher']),
                      _buildInfoRow('Students', '${classData['students']}'),
                      _buildInfoRow('Start Date', classData['startDate']),
                      _buildInfoRow('End Date', classData['endDate']),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildInfoSection(context, 'Statistics', [
                      _buildInfoRow('Attendance Rate', '${classData['attendance']}%'),
                      _buildInfoRow('Next Class', classData['nextClass']),
                      _buildInfoRow('Total Classes', '24'),
                      _buildInfoRow('Completed Classes', '20'),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    _buildInfoSection(context, 'Description', [
                      _buildInfoRow('', classData['description']),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to attendance
                            },
                            icon: const Icon(Icons.assignment),
                            label: const Text('View Attendance'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to students
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('View Students'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
