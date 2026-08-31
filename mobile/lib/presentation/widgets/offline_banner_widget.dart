import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/network/network_connectivity_service.dart';

class OfflineBannerWidget extends StatefulWidget {
  final Widget child;

  const OfflineBannerWidget({super.key, required this.child});

  @override
  State<OfflineBannerWidget> createState() => _OfflineBannerWidgetState();
}

class _OfflineBannerWidgetState extends State<OfflineBannerWidget> {
  StreamSubscription<bool>? _sub;
  bool _isOnline = true;
  bool _showReconnectedBanner = false;
  Timer? _reconnectHideTimer;

  @override
  void initState() {
    super.initState();
    _isOnline = networkConnectivityService.isOnline;

    _sub = networkConnectivityService.onConnectivityChanged.listen((isOnline) {
      if (!isOnline) {
        setState(() {
          _isOnline = false;
          _showReconnectedBanner = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isOnline = true;
            _showReconnectedBanner = true;
          });
        }

        _reconnectHideTimer?.cancel();
        _reconnectHideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showReconnectedBanner = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reconnectHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: const Color(0xFFEF4444), // Red banner
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Đang ở Chế độ Ngoại tuyến (Offline)',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_showReconnectedBanner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: const Color(0xFF10B981), // Emerald Green banner
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Đã khôi phục kết nối Internet! 🟢',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
