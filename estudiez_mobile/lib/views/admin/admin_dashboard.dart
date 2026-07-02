import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<RegistrationRequest> _requests = [];
  List<SchoolClass> _classes = [];

  // Announcement Form Fields
  final _announcementFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _audienceType = 'all'; // 'all' | 'class' | 'grade'
  String? _selectedTargetId;
  bool _isSendingNotification = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        api.getRegistrations(),
        api.getClasses(),
      ]);

      setState(() {
        _requests = results[0] as List<RegistrationRequest>;
        _classes = results[1] as List<SchoolClass>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching admin dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleApprove(int id) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await auth.apiService.approveRegistration(id, auth.currentUser?.userId ?? '');
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration request approved!'), behavior: SnackBarBehavior.floating),
        );
      }
    }
    _fetchAdminData();
  }

  void _handleReject(int id) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await auth.apiService.rejectRegistration(id, auth.currentUser?.userId ?? '');
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration request rejected!'), behavior: SnackBarBehavior.floating),
        );
      }
    }
    _fetchAdminData();
  }

  void _dispatchAnnouncement() async {
    if (!_announcementFormKey.currentState!.validate()) return;

    setState(() => _isSendingNotification = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.apiService.sendNotification(
      _titleController.text.trim(),
      _contentController.text.trim(),
      _audienceType.toUpperCase(),
      _selectedTargetId,
      auth.currentUser?.userId ?? '',
    );

    setState(() => _isSendingNotification = false);

    if (success) {
      _titleController.clear();
      _contentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement broadcasted successfully!'), behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to broadcast announcement.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final List<Widget> children = [
      _buildRegistrationsTab(),
      _buildAnnouncementTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Admin Dashboard' : 'Broadcast Announcement'),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFED7D31),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.approval_outlined), activeIcon: Icon(Icons.approval), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: 'Broadcast'),
        ],
      ),
    );
  }

  // ─── REGISTRATIONS TAB ───
  Widget _buildRegistrationsTab() {
    final pendingRequests = _requests.where((r) => r.status == 'pending').toList();

    if (pendingRequests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text(
                'All caught up! No pending registration requests.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, idx) {
        final request = pendingRequests[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2540)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED7D31).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.role.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFED7D31), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Email: ${request.email}', style: const TextStyle(fontSize: 13)),
                if (request.phone != null) Text('Phone: ${request.phone}', style: const TextStyle(fontSize: 13)),
                Text('Date Submitted: ${request.submittedAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _handleReject(request.id),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _handleApprove(request.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── ANNOUNCEMENT TAB ───
  Widget _buildAnnouncementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _announcementFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Broadcast Announcement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Send notifications directly to student and parent devices.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Announcement Title',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter title';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Content
            TextFormField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Announcement Body / Content',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter content body';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target Audience Type Dropdown
            DropdownButtonFormField<String>(
              value: _audienceType,
              decoration: const InputDecoration(
                labelText: 'Target Audience Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Users')),
                DropdownMenuItem(value: 'class', child: Text('Specific Class')),
                DropdownMenuItem(value: 'grade', child: Text('Specific Grade')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _audienceType = val;
                    _selectedTargetId = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Conditional Target Selector
            if (_audienceType == 'class')
              DropdownButtonFormField<String>(
                value: _selectedTargetId,
                decoration: const InputDecoration(
                  labelText: 'Select Target Class',
                  border: OutlineInputBorder(),
                ),
                items: _classes.map((c) {
                  return DropdownMenuItem(value: c.classId.toString(), child: Text(c.name));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedTargetId = val);
                },
                validator: (val) {
                  if (_audienceType == 'class' && val == null) return 'Please select class';
                  return null;
                },
              ),

            if (_audienceType == 'grade')
              DropdownButtonFormField<String>(
                value: _selectedTargetId,
                decoration: const InputDecoration(
                  labelText: 'Select Target Grade',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '10', child: Text('Grade 10')),
                  DropdownMenuItem(value: '11', child: Text('Grade 11')),
                  DropdownMenuItem(value: '12', child: Text('Grade 12')),
                ],
                onChanged: (val) {
                  setState(() => _selectedTargetId = val);
                },
                validator: (val) {
                  if (_audienceType == 'grade' && val == null) return 'Please select grade';
                  return null;
                },
              ),

            const SizedBox(height: 32),

            // Send Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSendingNotification ? null : _dispatchAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2540),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded),
                label: _isSendingNotification
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Broadcast Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
