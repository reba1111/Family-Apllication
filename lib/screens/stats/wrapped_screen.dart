import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../models/relationship_stats.dart';
import '../../../services/firestore_service.dart';

class WrappedScreen extends StatefulWidget {
  final UserModel me;
  final String partnerName;

  const WrappedScreen({
    super.key,
    required this.me,
    required this.partnerName,
  });

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  RelationshipStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (widget.me.coupleId == null) return;
    try {
      final stats = await FirestoreService().getRelationshipStats(widget.me.coupleId!);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error implicitly
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF13131A),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_stats == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF13131A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('ناتوانرێت ئامارەکان بهێنرێن', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final pages = [
      _buildWelcomePage(),
      _buildMemoriesPage(),
      _buildGoalsPage(),
      _buildFundsPage(),
      _buildQuizzesPage(),
      _buildNotesPage(),
      _buildSummaryPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return pages[index];
            },
          ),
          
          // Progress Indicator
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(
                pages.length,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 60,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return _buildPage(
      colors: const [Color(0xFF2E3192), Color(0xFF1BFFFF)],
      icon: Icons.auto_awesome,
      title: 'ئامادەیت؟',
      subtitle: 'با سەیری ئامارەکانی پەیوەندییەکەتان بکەین لەم ماوەیەدا...',
      hint: 'بڕۆ خوارەوە ▼',
    );
  }

  Widget _buildMemoriesPage() {
    return _buildPage(
      colors: const [Color(0xFFFF0844), Color(0xFFFFB199)],
      icon: Icons.camera_alt_rounded,
      title: 'یادگارییەکان 📸',
      contentWidget: _buildAnimatedNumber(_stats!.totalMemories, 'وێنە و یادگاری'),
      subtitle: 'هەموو ساتێکی پێکەوەبوونتان جوانە!',
    );
  }

  Widget _buildGoalsPage() {
    return _buildPage(
      colors: const [Color(0xFF0BA360), Color(0xFF3CB0FD)],
      icon: Icons.flag_rounded,
      title: 'ئامانجەکان 🎯',
      contentWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAnimatedNumber(_stats!.totalGoals, 'دانراو', size: 40),
          _buildAnimatedNumber(_stats!.completedGoals, 'بەدەستهاتوو', size: 50, color: Colors.yellowAccent),
        ],
      ),
      subtitle: 'پێکەوە هیچ شتێک مەحاڵ نییە!',
    );
  }

  Widget _buildFundsPage() {
    final myFunds = _stats!.userFunds[widget.me.uid] ?? 0.0;
    
    // Partner's ID is not strictly required if we just find the 'other' key, but we can iterate.
    double partnerFunds = 0.0;
    for (var entry in _stats!.userFunds.entries) {
      if (entry.key != widget.me.uid) {
        partnerFunds += entry.value;
      }
    }

    String topSpender = '';
    if (myFunds > partnerFunds) {
      topSpender = 'تۆ زیاترت پاشەکەوت کردووە! 🤑';
    } else if (partnerFunds > myFunds) {
      topSpender = '${widget.partnerName} زیاتری پاشەکەوت کردووە! 💸';
    } else {
      topSpender = 'هەردووکتان وەک یەک! 🤝';
    }

    return _buildPage(
      colors: const [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      icon: Icons.account_balance_wallet_rounded,
      title: 'سندوقی ئامانجەکان 💰',
      contentWidget: Column(
        children: [
          Text(topSpender, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFundCard('تۆ', myFunds),
              _buildFundCard(widget.partnerName, partnerFunds),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesPage() {
    return _buildPage(
      colors: const [Color(0xFF654EA3), Color(0xFFEA8D8D)],
      icon: Icons.quiz_rounded,
      title: 'کویزەکان 🤔',
      contentWidget: Column(
        children: [
          _buildAnimatedNumber(_stats!.totalQuizzes, 'پرسیار کراوە', size: 40),
          const SizedBox(height: 16),
          _buildAnimatedNumber(_stats!.quizzesAnswered, 'وەڵام دراوەتەوە', size: 40),
        ],
      ),
      subtitle: 'تا چەند یەکتر دەناسن؟',
    );
  }

  Widget _buildNotesPage() {
    return _buildPage(
      colors: const [Color(0xFFD4145A), Color(0xFFFBB03B)],
      icon: Icons.favorite_rounded,
      title: 'نامە شاراوەکان 💌',
      contentWidget: _buildAnimatedNumber(_stats!.totalNotes, 'نامە گۆڕدراوەتەوە'),
      subtitle: 'پڕ لە خۆشەویستی و سۆز!',
    );
  }

  Widget _buildSummaryPage() {
    return _buildPage(
      colors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
      icon: Icons.favorite,
      title: 'ئەمە تەنها سەرەتایە...',
      subtitle: 'بە هیوای داهاتوویەکی پڕ لە خۆشەویستی زیاتر بۆ هەردووکتان! ❤️',
      hint: 'گەڕانەوە بۆ داشبۆرد',
    );
  }

  Widget _buildFundCard(String name, double amount) {
    return Column(
      children: [
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: amount),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Text(
              '\$${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedNumber(int end, String label, {double size = 80, Color color = Colors.white}) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: end.toDouble()),
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                color: color,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
            );
          },
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPage({
    required List<Color> colors,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? contentWidget,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              if (contentWidget != null) ...[
                const SizedBox(height: 40),
                contentWidget,
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 40),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
              if (hint != null) ...[
                const Spacer(),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
