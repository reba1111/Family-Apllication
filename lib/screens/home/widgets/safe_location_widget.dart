import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class SafeLocationWidget extends StatefulWidget {
  final String currentUserId;
  final String? partnerId;

  const SafeLocationWidget({
    super.key,
    required this.currentUserId,
    this.partnerId,
  });

  @override
  State<SafeLocationWidget> createState() => _SafeLocationWidgetState();
}

class _SafeLocationWidgetState extends State<SafeLocationWidget> {
  final fs = FirestoreService();
  bool _isLoading = false;

  Future<void> _shareLocation(String status) async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('تکایە خزمەتگوزاری لۆکەیشن (GPS) هەڵبکە.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('مۆڵەتی لۆکەیشن نەدراوە.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('مۆڵەتی لۆکەیشن بۆ هەمیشە ڕەتکراوەتەوە، لە ڕێکخستنەکان چاکی بکە.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await fs.updateLocation(
        widget.currentUserId,
        position.latitude,
        position.longitude,
        status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لۆکەیشنت نێردرا: $status', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نەتوانرا نەخشە بکرێتەوە')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('سەلامەتی و لۆکەیشن', style: AppTheme.headlineMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('لۆکەیشنەکەم بنێرە', style: AppTheme.bodyLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _shareLocation('من لێرەم 📍'),
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('من لێرەم', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _shareLocation('گەیشتمە ماڵەوە 🏠'),
                      icon: const Icon(Icons.home, size: 18),
                      label: const Text('گەیشتم', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        if (widget.partnerId != null) ...[
          const SizedBox(height: 16),
          StreamBuilder<UserModel?>(
            stream: fs.streamUser(widget.partnerId!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final partner = snapshot.data!;

              if (partner.lastLocationLat == null || partner.lastLocationLng == null) {
                return const SizedBox();
              }

              final timeAgo = _getTimeAgo(partner.locationUpdatedAt);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current location card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.1),
                          AppTheme.accent.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.map, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(partner.displayName, style: AppTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                partner.locationStatus ?? 'لۆکەیشنی ناردووە',
                                style: AppTheme.titleLarge.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'لەوەتەی: $timeAgo',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, color: AppTheme.primary),
                          onPressed: () => _openMaps(partner.lastLocationLat!, partner.lastLocationLng!),
                        ),
                      ],
                    ),
                  ),

                  // History list (already loaded — no extra DB read!)
                  if (partner.locationHistory.length > 1) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('مێژووی لۆکەیشن', style: AppTheme.bodyMedium.copyWith(fontSize: 12, color: Colors.white54)),
                    ),
                    ...partner.locationHistory.skip(1).map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 16, color: Colors.white38),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.status,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            Text(
                              _getTimeAgo(entry.createdAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _openMaps(entry.lat, entry.lng),
                              child: const Icon(Icons.location_on, size: 16, color: Colors.white38),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'نەزانراو';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ئێستا';
    if (diff.inMinutes < 60) return '${diff.inMinutes} خولەک پێش ئێستا';
    if (diff.inHours < 24) return '${diff.inHours} کاتژمێر پێش ئێستا';
    return DateFormat('MM/dd hh:mm a').format(date);
  }
}
