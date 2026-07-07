import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/partner_tab.dart';
import '../lessons/lessons_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user;
      _loading = false;
    } else {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await AuthService().getUserModel(uid);
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final coupleId = _user!.coupleId;
    final uid = _user!.uid;
    final partnerId = _user!.partnerId;

    final tabs = [
      DashboardTab(user: _user!),
      if (coupleId != null) LessonsScreen(coupleId: coupleId),
      if (coupleId != null) TasksScreen(
        coupleId: coupleId, 
        currentUserId: uid, 
        partnerName: _user!.partnerNickname ?? 'هاوسەر',
      ),
      ProfileTab(user: _user!),
      if (coupleId != null && partnerId != null)
        PartnerTab(coupleId: coupleId, partnerId: partnerId, me: _user!),
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'ماڵەوە',
      ),
      if (coupleId != null)
        const BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book_rounded),
          label: 'وانەکان',
        ),
      if (coupleId != null)
        const BottomNavigationBarItem(
          icon: Icon(Icons.task_outlined),
          activeIcon: Icon(Icons.task_rounded),
          label: 'تاسکەکان',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person_rounded),
        label: 'پرۆفایل',
      ),
      if (coupleId != null && partnerId != null)
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite_rounded),
          label: 'هاوسەر',
        ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex.clamp(0, tabs.length - 1),
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex.clamp(0, navItems.length - 1),
          onTap: (i) => setState(() => _currentIndex = i),
          items: navItems,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.onSurfaceMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
        ),
      ),
    );
  }
}
