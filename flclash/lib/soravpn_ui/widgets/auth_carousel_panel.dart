import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_clash/soravpn_ui/widgets/starry_night_background.dart';

class AuthCarouselPanel extends StatefulWidget {
  final int? fixedIndex;

  const AuthCarouselPanel({super.key, this.fixedIndex});

  @override
  State<AuthCarouselPanel> createState() => _AuthCarouselPanelState();
}

class _AuthCarouselPanelState extends State<AuthCarouselPanel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  final List<Map<String, String>> _carouselItems = [
    {
      'image': 'assets/images/internet-on-the-go.svg',
      'title': '随时随地',
      'desc': '支持多设备同步，随时随地畅享网络自由',
    },
    {
      'image': 'assets/images/real-time-sync.svg',
      'title': '实时同步',
      'desc': '多设备实时同步，无缝切换，畅享流畅体验',
    },
    {
      'image': 'assets/images/usecurity.svg',
      'title': '安全可靠',
      'desc': '企业级加密技术，保护您的网络隐私和数据安全',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fixedIndex != null) {
      _currentPage = widget.fixedIndex!;
      // Wait for build to jump
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    } else {
      _startCarousel();
    }
  }
  
  @override
  void didUpdateWidget(AuthCarouselPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fixedIndex != oldWidget.fixedIndex) {
      _carouselTimer?.cancel();
      if (widget.fixedIndex != null) {
        _currentPage = widget.fixedIndex!;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut
          );
        }
      } else {
        _startCarousel();
      }
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _carouselItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StarryNightBackground(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _carouselItems.length,
                itemBuilder: (context, index) {
                  final item = _carouselItems[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset(
                          item['image']!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['desc']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_carouselItems.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
