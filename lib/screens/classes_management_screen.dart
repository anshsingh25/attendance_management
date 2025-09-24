import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ClassesManagementScreen extends StatefulWidget {
  const ClassesManagementScreen({super.key});

  @override
  State<ClassesManagementScreen> createState() => _ClassesManagementScreenState();
}

class _ClassesManagementScreenState extends State<ClassesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
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
        title: const Text('Classes Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddClassDialog,
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
          // Classes List
          Expanded(
            child: _filteredClasses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredClasses.length,
                    itemBuilder: (context, index) {
                      final cls = _filteredClasses[index];
                      return _buildClassCard(cls);
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

  Widget _buildClassCard(Map<String, dynamic> cls) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls['name'],
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cls['code'],
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Room', cls['room']),
                ),
                Expanded(
                  child: _buildInfoItem('Students', '${cls['students']}'),
                ),
                Expanded(
                  child: _buildInfoItem('Teacher', cls['teacher']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule: ${cls['schedule']}',
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewClassDetails(cls),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editClass(cls),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _manageStudents(cls),
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('Students'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteClass(cls),
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

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddClassDialog(
        onClassAdded: (cls) {
          setState(() {
            _classes.add(cls);
            _filterClasses();
          });
        },
      ),
    );
  }

  void _viewClassDetails(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) => _ClassDetailsDialog(classData: cls),
    );
  }

  void _editClass(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) => _EditClassDialog(
        classData: cls,
        onClassUpdated: (updatedClass) {
          setState(() {
            final index = _classes.indexWhere((c) => c['id'] == cls['id']);
            if (index != -1) {
              _classes[index] = updatedClass;
              _filterClasses();
            }
          });
        },
      ),
    );
  }

  void _manageStudents(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) => _ManageStudentsDialog(classData: cls),
    );
  }

  void _deleteClass(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete ${cls['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _classes.removeWhere((c) => c['id'] == cls['id']);
                _filterClasses();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${cls['name']} deleted successfully')),
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

class _AddClassDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onClassAdded;

  const _AddClassDialog({required this.onClassAdded});

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _roomController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _teacherController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _studentsController = TextEditingController();
  String _selectedStatus = 'Active';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Class'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) => value?.isEmpty == true ? 'Class name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Class Code'),
                validator: (value) => value?.isEmpty == true ? 'Class code is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room'),
                validator: (value) => value?.isEmpty == true ? 'Room is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(labelText: 'Schedule'),
                validator: (value) => value?.isEmpty == true ? 'Schedule is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(labelText: 'Teacher'),
                validator: (value) => value?.isEmpty == true ? 'Teacher is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentsController,
                decoration: const InputDecoration(labelText: 'Number of Students'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Number of students is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
              final cls = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': _nameController.text,
                'code': _codeController.text,
                'room': _roomController.text,
                'schedule': _scheduleController.text,
                'teacher': _teacherController.text,
                'students': int.parse(_studentsController.text),
                'status': _selectedStatus,
                'startDate': _startDate.toIso8601String().split('T')[0],
                'endDate': _endDate.toIso8601String().split('T')[0],
                'description': _descriptionController.text,
              };
              widget.onClassAdded(cls);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class added successfully')),
              );
            }
          },
          child: const Text('Add Class'),
        ),
      ],
    );
  }
}

class _ClassDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassDetailsDialog({required this.classData});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(classData['name']),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Class Code', classData['code']),
            _buildDetailRow('Room', classData['room']),
            _buildDetailRow('Schedule', classData['schedule']),
            _buildDetailRow('Teacher', classData['teacher']),
            _buildDetailRow('Students', '${classData['students']}'),
            _buildDetailRow('Status', classData['status']),
            _buildDetailRow('Start Date', classData['startDate']),
            _buildDetailRow('End Date', classData['endDate']),
            _buildDetailRow('Description', classData['description']),
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

class _EditClassDialog extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Function(Map<String, dynamic>) onClassUpdated;

  const _EditClassDialog({
    required this.classData,
    required this.onClassUpdated,
  });

  @override
  State<_EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<_EditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _roomController;
  late TextEditingController _scheduleController;
  late TextEditingController _teacherController;
  late TextEditingController _descriptionController;
  late TextEditingController _studentsController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classData['name']);
    _codeController = TextEditingController(text: widget.classData['code']);
    _roomController = TextEditingController(text: widget.classData['room']);
    _scheduleController = TextEditingController(text: widget.classData['schedule']);
    _teacherController = TextEditingController(text: widget.classData['teacher']);
    _descriptionController = TextEditingController(text: widget.classData['description']);
    _studentsController = TextEditingController(text: widget.classData['students'].toString());
    _selectedStatus = widget.classData['status'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Class'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) => value?.isEmpty == true ? 'Class name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Class Code'),
                validator: (value) => value?.isEmpty == true ? 'Class code is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room'),
                validator: (value) => value?.isEmpty == true ? 'Room is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(labelText: 'Schedule'),
                validator: (value) => value?.isEmpty == true ? 'Schedule is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(labelText: 'Teacher'),
                validator: (value) => value?.isEmpty == true ? 'Teacher is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentsController,
                decoration: const InputDecoration(labelText: 'Number of Students'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Number of students is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
              final updatedClass = Map<String, dynamic>.from(widget.classData);
              updatedClass['name'] = _nameController.text;
              updatedClass['code'] = _codeController.text;
              updatedClass['room'] = _roomController.text;
              updatedClass['schedule'] = _scheduleController.text;
              updatedClass['teacher'] = _teacherController.text;
              updatedClass['students'] = int.parse(_studentsController.text);
              updatedClass['description'] = _descriptionController.text;
              updatedClass['status'] = _selectedStatus;
              
              widget.onClassUpdated(updatedClass);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class updated successfully')),
              );
            }
          },
          child: const Text('Update Class'),
        ),
      ],
    );
  }
}

class _ManageStudentsDialog extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ManageStudentsDialog({required this.classData});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Students in ${classData['name']}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: 10, // Mock data
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text('Student ${index + 1}'),
              subtitle: Text('ID: STU${(index + 1).toString().padLeft(3, '0')}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  // Remove student logic
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Add student logic
          },
          child: const Text('Add Student'),
        ),
      ],
    );
  }
}
