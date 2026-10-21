import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How far from the top of the screen the back / share / like row sits on a
/// project page's hero picture — the same in every portal.
///
/// Close to the top: on a punch-hole screen the safe-area inset (54dp on the
/// test device) runs well below the status-bar text (~24dp), so parking the
/// row under the whole inset left an obvious empty band above it. Take some of
/// that slack back, with a 26dp floor so the buttons still clear the clock on
/// a device whose inset is only the status bar.
double heroActionsTop(BuildContext context) =>
    math.max(MediaQuery.of(context).padding.top - 12, 26.0);
