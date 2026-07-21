import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/tv_pairing_service.dart';

/// Sign-in-by-QR screen, shown on Android TV (where typing an email and
/// password with a remote is painful) and reachable from the phone's own
/// auth screen too. Shows a QR code + short fallback code; scanning it on
/// time.ivaan.cc while signed in on the phone completes the sign-in here.
class TvPairingScreen extends StatefulWidget {
  const TvPairingScreen({super.key});

  @override
  State<TvPairingScreen> createState() => _TvPairingScreenState();
}

class _TvPairingScreenState extends State<TvPairingScreen> {
  final _pairing = TvPairingService();
  String? _code;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  Future<void> _startPairing() async {
    setState(() => _error = null);
    final code = await _pairing.start(
      onSignedIn: () {
        if (!mounted) return;
        Navigator.of(context).pop();
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _error = message);
      },
    );
    if (mounted) setState(() => _code = code);
  }

  @override
  void dispose() {
    _pairing.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final code = _code;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SIGN IN',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 4,
                  color: color.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 32),
              if (code != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: _pairing.pairingUrl,
                    version: QrVersions.auto,
                    size: 240,
                  ),
                )
              else
                const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 28),
              Text(
                'Scan the QR code, or go to',
                style: TextStyle(color: color.withOpacity(0.55)),
              ),
              Text(
                'time.ivaan.cc',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              Text(
                'and enter this code:',
                style: TextStyle(color: color.withOpacity(0.55)),
              ),
              const SizedBox(height: 12),
              Text(
                code ?? '......',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 8),
                TextButton(onPressed: _startPairing, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
