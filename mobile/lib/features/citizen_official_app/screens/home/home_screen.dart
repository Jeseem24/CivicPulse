import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/state/notification_provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/my_complaints_tab.dart';
import 'tabs/civic_map_tab.dart';
import 'tabs/profile_tab.dart';
import '../complaint/report_complaint_screen.dart';
import '../notification/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _citizenTabs = const [
    HomeTab(),
    MyComplaintsTab(),
    CivicMapTab(),
    ProfileTab(),
  ];

  final List<Widget> _adminTabs = const [
    MyComplaintsTab(),
    CivicMapTab(),
    ProfileTab(),
  ];

  final List<String> _citizenTitles = const [
    'Civic Connect',
    'My Reports',
    'Civic Map',
    'Citizen Profile',
  ];

  final List<String> _adminTitles = const [
    'Admin Dashboard',
    'Civic Map',
    'Official Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isUser = authProvider.currentUser?.role == 'USER';

    final activeTabs = isUser ? _citizenTabs : _adminTabs;
    final activeTitles = isUser ? _citizenTitles : _adminTitles;

    // Safety check to prevent index out of bounds on role switch
    if (_currentIndex >= activeTabs.length) {
      _currentIndex = 0;
    }

    final appBarTitle = activeTitles[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle),
        automaticallyImplyLeading: false,
        actions: isUser
            ? [
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    final count = notifProvider.unreadCount;
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: AppColors.severityHigh,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
              ]
            : null,
      ),
      body: activeTabs[_currentIndex],
      floatingActionButton: (isUser && _currentIndex != 2 && _currentIndex != 3) 
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
        type: BottomNavigationBarType.fixed,
        items: isUser
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
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
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
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
