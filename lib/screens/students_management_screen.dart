import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() => _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    // Mock data - in real app, this would come from API
    _students = [
      {
        'id': '1',
        'name': 'John Doe',
        'email': 'john.doe@university.edu',
        'studentId': 'STU001',
        'course': 'Computer Science',
        'year': '3rd Year',
        'attendance': 85.5,
        'status': 'Active',
        'phone': '+1 234-567-8900',
        'enrollmentDate': '2022-09-01',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'email': 'jane.smith@university.edu',
        'studentId': 'STU002',
        'course': 'Mathematics',
        'year': '2nd Year',
        'attendance': 92.3,
        'status': 'Active',
        'phone': '+1 234-567-8901',
        'enrollmentDate': '2023-09-01',
      },
      {
        'id': '3',
        'name': 'Mike Johnson',
        'email': 'mike.johnson@university.edu',
        'studentId': 'STU003',
        'course': 'Physics',
        'year': '4th Year',
        'attendance': 78.9,
        'status': 'Active',
        'phone': '+1 234-567-8902',
        'enrollmentDate': '2021-09-01',
      },
      {
        'id': '4',
        'name': 'Sarah Wilson',
        'email': 'sarah.wilson@university.edu',
        'studentId': 'STU004',
        'course': 'Chemistry',
        'year': '1st Year',
        'attendance': 95.2,
        'status': 'Active',
        'phone': '+1 234-567-8903',
        'enrollmentDate': '2024-09-01',
      },
      {
        'id': '5',
        'name': 'David Brown',
        'email': 'david.brown@university.edu',
        'studentId': 'STU005',
        'course': 'Computer Science',
        'year': '3rd Year',
        'attendance': 67.8,
        'status': 'Inactive',
        'phone': '+1 234-567-8904',
        'enrollmentDate': '2022-09-01',
      },
    ];
    _filteredStudents = List.from(_students);
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _students.where((student) {
        final matchesSearch = student['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            student['studentId'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            student['email'].toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesFilter = _selectedFilter == 'All' || student['status'] == _selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
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
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterStudents();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _filterStudents(),
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
                            _filterStudents();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Students List
          Expanded(
            child: _filteredStudents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(student);
                    },
                  ),
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
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No students found',
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

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    student['name'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        student['studentId'],
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: student['status'] == 'Active' 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    student['status'],
                    style: AppTheme.labelSmall.copyWith(
                      color: student['status'] == 'Active' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Course', student['course']),
                ),
                Expanded(
                  child: _buildInfoItem('Year', student['year']),
                ),
                Expanded(
                  child: _buildInfoItem('Attendance', '${student['attendance']}%'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewStudentDetails(student),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editStudent(student),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteStudent(student),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddStudentDialog(
        onStudentAdded: (student) {
          setState(() {
            _students.add(student);
            _filterStudents();
          });
        },
      ),
    );
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => _StudentDetailsDialog(student: student),
    );
  }

  void _editStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => _EditStudentDialog(
        student: student,
        onStudentUpdated: (updatedStudent) {
          setState(() {
            final index = _students.indexWhere((s) => s['id'] == student['id']);
            if (index != -1) {
              _students[index] = updatedStudent;
              _filterStudents();
            }
          });
        },
      ),
    );
  }

  void _deleteStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _students.removeWhere((s) => s['id'] == student['id']);
                _filterStudents();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student['name']} deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onStudentAdded;

  const _AddStudentDialog({required this.onStudentAdded});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCourse = 'Computer Science';
  String _selectedYear = '1st Year';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value?.isEmpty == true ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (value) => value?.isEmpty == true ? 'Student ID is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCourse,
                decoration: const InputDecoration(labelText: 'Course'),
                items: ['Computer Science', 'Mathematics', 'Physics', 'Chemistry', 'Biology']
                    .map((course) => DropdownMenuItem(value: course, child: Text(course)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCourse = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(labelText: 'Year'),
                items: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                    .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedYear = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final student = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': _nameController.text,
                'email': _emailController.text,
                'studentId': _studentIdController.text,
                'course': _selectedCourse,
                'year': _selectedYear,
                'attendance': 0.0,
                'status': 'Active',
                'phone': _phoneController.text,
                'enrollmentDate': DateTime.now().toIso8601String().split('T')[0],
              };
              widget.onStudentAdded(student);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student added successfully')),
              );
            }
          },
          child: const Text('Add Student'),
        ),
      ],
    );
  }
}

class _StudentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentDetailsDialog({required this.student});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(student['name']),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Student ID', student['studentId']),
            _buildDetailRow('Email', student['email']),
            _buildDetailRow('Phone', student['phone']),
            _buildDetailRow('Course', student['course']),
            _buildDetailRow('Year', student['year']),
            _buildDetailRow('Attendance', '${student['attendance']}%'),
            _buildDetailRow('Status', student['status']),
            _buildDetailRow('Enrollment Date', student['enrollmentDate']),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EditStudentDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final Function(Map<String, dynamic>) onStudentUpdated;

  const _EditStudentDialog({
    required this.student,
    required this.onStudentUpdated,
  });

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;
  late TextEditingController _phoneController;
  late String _selectedCourse;
  late String _selectedYear;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student['name']);
    _emailController = TextEditingController(text: widget.student['email']);
    _studentIdController = TextEditingController(text: widget.student['studentId']);
    _phoneController = TextEditingController(text: widget.student['phone']);
    _selectedCourse = widget.student['course'];
    _selectedYear = widget.student['year'];
    _selectedStatus = widget.student['status'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value?.isEmpty == true ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (value) => value?.isEmpty == true ? 'Student ID is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCourse,
                decoration: const InputDecoration(labelText: 'Course'),
                items: ['Computer Science', 'Mathematics', 'Physics', 'Chemistry', 'Biology']
                    .map((course) => DropdownMenuItem(value: course, child: Text(course)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCourse = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(labelText: 'Year'),
                items: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                    .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedYear = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Active', 'Inactive']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedStudent = Map<String, dynamic>.from(widget.student);
              updatedStudent['name'] = _nameController.text;
              updatedStudent['email'] = _emailController.text;
              updatedStudent['studentId'] = _studentIdController.text;
              updatedStudent['phone'] = _phoneController.text;
              updatedStudent['course'] = _selectedCourse;
              updatedStudent['year'] = _selectedYear;
              updatedStudent['status'] = _selectedStatus;
              
              widget.onStudentUpdated(updatedStudent);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student updated successfully')),
              );
            }
          },
          child: const Text('Update Student'),
        ),
      ],
    );
  }
}
