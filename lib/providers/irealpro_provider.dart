import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class IRealProProvider with ChangeNotifier {
  bool _isInstalled = false;

  bool get isInstalled => _isInstalled;

  Future<void> checkInstallation() async {
    const irealTestUrl = 'irealbook://';
    final canOpen = await canLaunchUrl(Uri.parse(irealTestUrl));
    _isInstalled = canOpen;
    notifyListeners();
  }
}
