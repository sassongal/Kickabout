import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';
import 'package:path_provider/path_provider.dart';

/// Service for generating shareable team lineup images
///
/// Creates a beautifully designed image with:
/// - Kattrick branding
/// - Team colors and names
/// - Player lists organized by team
/// - Professional gradient background
///
/// Usage:
/// ```dart
/// final imageFile = await TeamImageGenerator.generateTeamImage(
///   teams: teams,
///   userMap: userMap,
///   balanceScore: 85.5,
/// );
/// await Share.shareXFiles([XFile(imageFile.path)]);
/// ```
class TeamImageGenerator {
  static const double _imageWidth = 1080;
  static const double _imageHeight = 1920;
  static const double _padding = 40;
  static const double _teamSpacing = 60;
  static const double _playerSpacing = 24;

  /// Generate team lineup image and save to temporary file
  static Future<File> generateTeamImage({
    required List<Team> teams,
    required Map<String, User> userMap,
    double? balanceScore,
    String? eventName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    _drawBackground(canvas);

    // Draw header with logo and title
    await _drawHeader(canvas, eventName);

    // Draw balance score badge if available
    if (balanceScore != null) {
      _drawBalanceScore(canvas, balanceScore);
    }

    // Draw teams
    double currentY = 320;
    for (int i = 0; i < teams.length; i++) {
      currentY = await _drawTeam(
        canvas,
        teams[i],
        userMap,
        currentY,
        i,
      );
      currentY += _teamSpacing;
    }

    // Draw footer with branding
    _drawFooter(canvas);

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(_imageWidth.toInt(), _imageHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/kattrick_teams_$timestamp.png');
    await file.writeAsBytes(buffer);

    return file;
  }

  /// Draw gradient background
  static void _drawBackground(Canvas canvas) {
    const rect = Rect.fromLTWH(0, 0, _imageWidth, _imageHeight);
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(0, _imageHeight),
      [
        const Color(0xFF0B0C10), // Dark background (top)
        const Color(0xFF1F2833), // Slightly lighter (bottom)
      ],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(rect, paint);

    // Add subtle grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (double x = 0; x < _imageWidth; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, _imageHeight), gridPaint);
    }
    for (double y = 0; y < _imageHeight; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(_imageWidth, y), gridPaint);
    }
  }

  /// Draw header with Kattrick logo and title
  static Future<void> _drawHeader(Canvas canvas, String? eventName) async {
    // Draw "Kattrick" text (logo text)
    final logoStyle = ui.TextStyle(
      color: const Color(0xFF66FCF1), // Kattrick cyan
      fontSize: 72,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    );

    final logoParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
    ),)
      ..pushStyle(logoStyle)
      ..addText('KATTRICK');

    final logoText = logoParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: _imageWidth));

    canvas.drawParagraph(logoText, const Offset(0, 60));

    // Draw title
    final titleStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 48,
      fontWeight: FontWeight.bold,
    );

    final titleParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
    ),)
      ..pushStyle(titleStyle)
      ..addText('🏆 כוחות המשחק 🏆');

    final titleText = titleParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: _imageWidth));

    canvas.drawParagraph(titleText, const Offset(0, 160));

    // Draw event name if provided
    if (eventName != null && eventName.isNotEmpty) {
      final eventStyle = ui.TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 28,
      );

      final eventParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ),)
        ..pushStyle(eventStyle)
        ..addText(eventName);

      final eventText = eventParagraph.build()
        ..layout(const ui.ParagraphConstraints(width: _imageWidth));

      canvas.drawParagraph(eventText, const Offset(0, 220));
    }
  }

  /// Draw balance score badge
  static void _drawBalanceScore(Canvas canvas, double score) {
    const x = _imageWidth - _padding - 160;
    const y = 240.0;

    // Draw badge background
    final badgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(x, y, 160, 60),
      const Radius.circular(30),
    );

    final badgePaint = Paint()
      ..color = _getBalanceColor(score).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(badgeRect, badgePaint);

    // Draw badge border
    final borderPaint = Paint()
      ..color = _getBalanceColor(score)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(badgeRect, borderPaint);

    // Draw score text
    final scoreStyle = ui.TextStyle(
      color: _getBalanceColor(score),
      fontSize: 32,
      fontWeight: FontWeight.bold,
    );

    final scoreParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ),)
      ..pushStyle(scoreStyle)
      ..addText('${score.toStringAsFixed(1)}%');

    final scoreText = scoreParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: 160));

    canvas.drawParagraph(scoreText, const Offset(x, y + 12));
  }

  /// Draw a single team with its players
  static Future<double> _drawTeam(
    Canvas canvas,
    Team team,
    Map<String, User> userMap,
    double startY,
    int teamIndex,
  ) async {
    double currentY = startY;

    // Draw team header card
    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_padding, currentY, _imageWidth - _padding * 2, 80),
      const Radius.circular(20),
    );

    // Team color
    final teamColor = _getTeamColor(team, teamIndex);

    // Draw header background with gradient
    final headerGradient = ui.Gradient.linear(
      Offset(_padding, currentY),
      Offset(_imageWidth - _padding, currentY),
      [
        teamColor.withValues(alpha: 0.3),
        teamColor.withValues(alpha: 0.1),
      ],
    );

    final headerPaint = Paint()..shader = headerGradient;
    canvas.drawRRect(headerRect, headerPaint);

    // Draw header border
    final borderPaint = Paint()
      ..color = teamColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(headerRect, borderPaint);

    // Draw team name
    final teamNameStyle = ui.TextStyle(
      color: teamColor,
      fontSize: 42,
      fontWeight: FontWeight.bold,
    );

    final teamNameParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.right,
    ),)
      ..pushStyle(teamNameStyle)
      ..addText(team.name);

    final teamNameText = teamNameParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: _imageWidth - _padding * 2 - 200));

    canvas.drawParagraph(teamNameText, Offset(_imageWidth - _padding - 200, currentY + 20));

    // Draw player count badge
    final countStyle = ui.TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 28,
    );

    final countParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
    ),)
      ..pushStyle(countStyle)
      ..addText('${team.playerIds.length} שחקנים');

    final countText = countParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: 200));

    canvas.drawParagraph(countText, Offset(_padding + 30, currentY + 26));

    currentY += 100;

    // Draw players
    for (int i = 0; i < team.playerIds.length; i++) {
      final playerId = team.playerIds[i];
      final user = userMap[playerId];

      if (user != null) {
        currentY = _drawPlayer(canvas, user, currentY, teamColor, i + 1);
        currentY += _playerSpacing;
      }
    }

    return currentY;
  }

  /// Draw a single player row
  static double _drawPlayer(
    Canvas canvas,
    User user,
    double y,
    Color teamColor,
    int index,
  ) {
    // Draw player card background
    final playerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_padding + 20, y, _imageWidth - _padding * 2 - 40, 60),
      const Radius.circular(12),
    );

    final cardPaint = Paint()
      ..color = const Color(0xFF1F2833).withValues(alpha: 0.5);

    canvas.drawRRect(playerRect, cardPaint);

    // Draw left accent bar
    final accentRect = Rect.fromLTWH(_padding + 20, y, 6, 60);
    final accentPaint = Paint()..color = teamColor.withValues(alpha: 0.6);
    canvas.drawRect(accentRect, accentPaint);

    // Draw player number circle
    final circleCenter = Offset(_padding + 80, y + 30);
    final circlePaint = Paint()
      ..color = teamColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(circleCenter, 20, circlePaint);

    final numberStyle = ui.TextStyle(
      color: teamColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    final numberParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ),)
      ..pushStyle(numberStyle)
      ..addText('$index');

    final numberText = numberParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: 40));

    canvas.drawParagraph(numberText, Offset(_padding + 60, y + 19));

    // Draw player name
    final nameStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.w500,
    );

    final nameParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.right,
    ),)
      ..pushStyle(nameStyle)
      ..addText(user.displayName ?? user.name);

    final nameText = nameParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: _imageWidth - _padding * 2 - 180));

    canvas.drawParagraph(nameText, Offset(_imageWidth - _padding - (_imageWidth - _padding * 2 - 140), y + 14));

    return y + 60;
  }

  /// Draw footer with branding
  static void _drawFooter(Canvas canvas) {
    const y = _imageHeight - 100;

    // Draw footer text
    final footerStyle = ui.TextStyle(
      color: const Color(0xFF66FCF1).withValues(alpha: 0.8),
      fontSize: 28,
      fontWeight: FontWeight.w500,
    );

    final footerParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ),)
      ..pushStyle(footerStyle)
      ..addText('💚 Created with Kattrick');

    final footerText = footerParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: _imageWidth));

    canvas.drawParagraph(footerText, const Offset(0, y));

    // Draw download prompt
    final promptStyle = ui.TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 22,
    );

    final promptParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ),)
      ..pushStyle(promptStyle)
      ..addText('הורד את האפליקציה: kattrick.app');

    final promptText = promptParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: _imageWidth));

    canvas.drawParagraph(promptText, const Offset(0, y + 40));
  }

  /// Get color for team based on team data or index
  static Color _getTeamColor(Team team, int index) {
    if (team.colorValue != null) {
      return Color(team.colorValue!);
    }

    // Fallback colors
    const colors = [
      Color(0xFFFF6B6B), // Red
      Color(0xFF4ECDC4), // Cyan
      Color(0xFFFFE66D), // Yellow
      Color(0xFF95E1D3), // Green
      Color(0xFFFF9A76), // Orange
    ];

    return colors[index % colors.length];
  }

  /// Get color for balance score
  static Color _getBalanceColor(double score) {
    if (score >= 85) return const Color(0xFF4ECDC4); // Cyan (excellent)
    if (score >= 70) return Colors.green;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }
}
