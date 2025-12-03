import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/widgets/optimized_image.dart';

class HubsCarousel extends StatefulWidget {
  final List<Hub> hubs;
  final String currentUserId;

  const HubsCarousel(
      {super.key, required this.hubs, required this.currentUserId});

  @override
  State<HubsCarousel> createState() => _HubsCarouselState();
}

class _HubsCarouselState extends State<HubsCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  final double _viewportFraction = 0.8;
  final double _scaleFactor = 0.8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hubs.isEmpty) return _buildEmptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('MY SQUADS',
              style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFF212121))),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.hubs.length,
            onPageChanged: (int index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * (1 - _scaleFactor)))
                        .clamp(0.0, 1.0);
                  } else {
                    value = index == _currentPage ? 1.0 : _scaleFactor;
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 200,
                      width: Curves.easeOut.transform(value) * 350,
                      child: child,
                    ),
                  );
                },
                child: _buildHubCard(widget.hubs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHubCard(Hub hub) {
    final isManager = hub.createdBy == widget.currentUserId ||
        (hub.roles[widget.currentUserId] == 'admin');
    return GestureDetector(
      onTap: () => context.push('/hubs/${hub.hubId}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
          gradient: isManager
              ? FuturisticColors.primaryGradient
              : const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hub.profileImageUrl != null && hub.profileImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87])
                      .createShader(rect),
                  blendMode: BlendMode.darken,
                  child: OptimizedImage(
                      imageUrl: hub.profileImageUrl!, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isManager
                                    ? Colors.orange
                                    : Colors.white54)),
                        child: Text(isManager ? 'ADMIN' : 'MEMBER',
                            style: GoogleFonts.orbitron(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isManager ? Colors.orange : Colors.white))),
                  ]),
                  const Spacer(),
                  Text(hub.name,
                      style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.people, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text('${hub.memberCount} Ballers',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.white70))
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        const Icon(Icons.group_off_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text('No Squads Yet',
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        TextButton(
            onPressed: () => context.push('/discover'),
            child: const Text('Find a Squad'))
      ]),
    );
  }
}
