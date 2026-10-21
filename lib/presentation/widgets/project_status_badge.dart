import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The project's status ("COMPLETED", "ONGOING", ...) on the project page,
/// beside the location pill under the title — never on the hero picture. One
/// look in every portal (a black pill with white spaced capitals), so the four
/// project pages can no longer drift apart.
class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge({super.key, required this.status});

  /// The status as the backend sends it; shown in capitals.
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.gelasio(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
