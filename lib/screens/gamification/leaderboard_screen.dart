import 'package:flutter/material.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/kicka_ball_logo.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'טבלת מובילים',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const KickaBallLogo(size: 120),
              const SizedBox(height: 32),
              Text(
                'בקרוב...',
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'אנחנו עובדים על מערכת טורנירים ומשחקים בין Hubs!',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'בקרוב תוכלו לראות כאן איזה Hub מוביל את הטבלה הארצית.',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
