import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'profiles_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ตัวแปรสำหรับเชื่อม Database และจัดการสถานะ ---
  String _activeProfileName = "กำลังโหลด...";
  String? _activeProfileImageUrl;
  String _mainProfileName = "กำลังโหลด...";
  String? _mainProfileImageUrl;
  int _selectedIndex = 0;
  String _activeProfileId = 'main';

  // Global Keys สำหรับสั่ง refresh ข้อมูลในแท็บประวัติและแท็บโปรไฟล์
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<HistoryTabState> _historyTabKey = GlobalKey<HistoryTabState>();
  final GlobalKey<ProfilesTabState> _profilesTabKey = GlobalKey<ProfilesTabState>();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ฟังก์ชันดึงข้อมูลชื่อจาก Supabase
  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. ดึงข้อมูลโปรไฟล์หลัก
        final mainData = await Supabase.instance.client
            .from('profiles')
            .select('full_name, image_url')
            .eq('id', user.id)
            .maybeSingle();

        String mainName = mainData?['full_name'] ?? "ผู้ใช้งาน";
        String? mainImg = mainData?['image_url'];

        // 2. ดึงข้อมูลโปรไฟล์ที่กำลังใช้งาน (Active Profile)
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
            // ถ้าไม่พบ sub profile (อาจถูกลบไปแล้ว) ให้สลับกลับเป็น main
            _activeProfileId = 'main';
            currentActiveName = mainName;
            currentActiveImg = mainImg;
          }
        }

        if (mounted) {
          setState(() {
            _mainProfileName = mainName;
            _mainProfileImageUrl = mainImg;
            _activeProfileName = currentActiveName;
            _activeProfileImageUrl = currentActiveImg;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _onProfileSwitched(String newProfileId, String newName, String? newImageUrl) {
    setState(() {
      _activeProfileId = newProfileId;
      _activeProfileName = newName;
      _activeProfileImageUrl = newImageUrl;
    });
    _historyTabKey.currentState?.fetchAllHistory();
  }

  void _onDataChanged() {
    // โหลดข้อมูลใหม่ทั้งหมดเมื่อมีการอัปเดตข้อมูลส่วนตัว
    _fetchUserData();
    _historyTabKey.currentState?.fetchAllHistory();
  }

  @override
  Widget build(BuildContext context) {
    // รายการหน้าแท็บทั้ง 3 หน้า
    final List<Widget> pages = [
      HomeTab(
        key: _homeTabKey,
        activeProfileId: _activeProfileId,
        activeProfileName: _activeProfileName,
        activeProfileImageUrl: _activeProfileImageUrl,
        onProfileTap: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
        onViewAllHistory: () {
          setState(() {
            _selectedIndex = 1;
          });
          _historyTabKey.currentState?.fetchAllHistory();
        },
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
        userName: _mainProfileName,
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
      
      // ส่วน Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1) {
              _historyTabKey.currentState?.fetchAllHistory();
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF009688),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26), 
              activeIcon: Icon(Icons.home, size: 26),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined, size: 26), 
              activeIcon: Icon(Icons.schedule, size: 26),
              label: 'ประวัติ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 26), 
              activeIcon: Icon(Icons.people, size: 26),
              label: 'โปรไฟล์อื่น',
            ),
          ],
        ),
      ),
    );
  }
}