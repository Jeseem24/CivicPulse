import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/state/auth_provider.dart';
import 'tabs/my_complaints_tab.dart';
import 'tabs/civic_map_tab.dart';
import 'tabs/profile_tab.dart';
import '../complaint/report_complaint_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MyComplaintsTab(),
    CivicMapTab(),
    ProfileTab(),
  ];

  final List<String> _titles = const [
    'My Grievances',
    'Civic Map',
    'Citizen Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isUser = authProvider.currentUser?.role == 'USER';
    final isLocalAdmin = authProvider.currentUser?.role == 'ADMIN';

    final appBarTitle = _currentIndex == 0
        ? (isLocalAdmin ? 'Admin Dashboard' : 'My Grievances')
        : (_currentIndex == 2
            ? (isLocalAdmin ? 'Official Profile' : 'Citizen Profile')
            : _titles[_currentIndex]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle),
        automaticallyImplyLeading: false,
      ),
      body: _tabs[_currentIndex],
      floatingActionButton: (isUser && _currentIndex != 2) 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportComplaintScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Civic Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
