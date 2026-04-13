import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PortalType { guest, user, cp, investor }

final portalProvider = StateProvider<PortalType>((ref) => PortalType.guest);
