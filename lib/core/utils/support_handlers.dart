import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';


class SupportHandlers {
  static const String whatsappNumber = '919876543210';
  static const String supportPhone = '+919930850993';
  static const String supportEmail = 'sales@m4group.in';
  static const String helpCenterUrl = 'http://localhost:5008/support/help-center';

  static const String scheduleVisitUrl = 'http://localhost:5008/booking/schedule-visit';
  static const String corporateAddress = '604, 6th Floor, M4 Aura Heights, Maulana Shaukat Ali Road, Grant Road, Mumbai - 400007';


  static Future<void> launchWhatsApp([String? phone]) async {
    // Using the full api.whatsapp.com link for better reliability
    final Uri url = Uri.parse('https://api.whatsapp.com/send?phone=${phone ?? whatsappNumber}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  static Future<void> launchCall([String? phone]) async {
    final Uri url = Uri.parse('tel:${phone ?? supportPhone}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching call: $e');
    }
  }

  static Future<void> launchEmail([String? email]) async {
    final Uri url = Uri.parse('mailto:${email ?? supportEmail}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }



  static Future<void> launchMap() async {
    // Using a more universal Google Maps URL that works better for redirection
    final String query = Uri.encodeComponent(corporateAddress);
    final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$query");
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
  }

  static Future<void> openMap(String address) async {
    final String query = Uri.encodeComponent(address);
    final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$query");
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
  }



  static Future<void> launchHelpCenter() async {
    final Uri url = Uri.parse(helpCenterUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}


