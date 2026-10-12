// main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'profiles_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String _activeProfileId = 'main';
  String _userName = 'ผู้ใช้งาน';

  // Global Keys สำหรับสั่ง refresh ข้อมูลในแต่ละแท็บ
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<HistoryTabState> _historyTabKey = GlobalKey<HistoryTabState>();
  final GlobalKey<ProfilesTabState> _profilesTabKey = GlobalKey<ProfilesTabState>();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  String? _activeProfileImageUrl;

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final mainData = await Supabase.instance.client
            .from('profiles')
            .select('full_name, image_url')
            .eq('id', user.id)
            .maybeSingle();

        String mainName = mainData?['full_name'] ?? "ผู้ใช้งาน";
        String? mainImg = mainData?['image_url'];

        String currentActiveName = mainName;
        String? currentActiveImg = mainImg;

        if (_activeProfileId != 'main') {
          final subData = await Supabase.instance.client
              .from('sub_profiles')
              .select('name, image_url')
              .eq('id', _activeProfileId)
              .eq('parent_user_id', user.id)
              .maybeSingle();

          if (subData != null) {
            currentActiveName = subData['name'] ?? "ผู้ใช้งาน";
            currentActiveImg = subData['image_url'];
          } else {
            _activeProfileId = 'main';
            currentActiveName = mainName;
            currentActiveImg = mainImg;
          }
        }

        if (mounted) {
          setState(() {
            _userName = currentActiveName;
            _activeProfileImageUrl = currentActiveImg;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  void _onProfileSwitched(String newProfileId, String newName, String? newImageUrl) {
    setState(() {
      _activeProfileId = newProfileId;
      _userName = newName;
      _activeProfileImageUrl = newImageUrl;
    });
    _historyTabKey.currentState?.fetchAllHistory();
  }

  void _onDataChanged() {
    _fetchUserData();
    _historyTabKey.currentState?.fetchAllHistory();
  }

  @override
  Widget build(BuildContext context) {
    // รายการแท็บทั้ง 3 หน้าที่แยกไฟล์แล้ว
    final List<Widget> pages = [
      HomeTab(
        key: _homeTabKey,
        activeProfileId: _activeProfileId,
        activeProfileName: _userName,
        activeProfileImageUrl: null,
        onViewAllHistory: () => setState(() => _selectedIndex = 1),
        onScanCompleted: () {
          _historyTabKey.currentState?.fetchAllHistory();
        },
      ),
      HistoryTab(
        key: _historyTabKey,
        activeProfileId: _activeProfileId,
      ),
      ProfilesTab(
        key: _profilesTabKey,
        activeProfileId: _activeProfileId,
        userName: _userName,
        onActiveProfileChanged: _onProfileSwitched,
        onDataChanged: _onDataChanged,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF009688),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'โปรไฟล์อื่น',
          ),
        ],
      ),
    );
  }
}
