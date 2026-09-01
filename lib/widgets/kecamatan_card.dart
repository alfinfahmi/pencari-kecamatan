import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kecamatan_model.dart';
import '../theme/app_theme.dart';

class KecamatanCard extends StatefulWidget {
  final KecamatanModel data;
  final bool isFavorite;
  final VoidCallback onTap; // "Hitung Waktu" -> buka DetailScreen
  final VoidCallback onToggleFavorite;
  final bool awalTerbuka;

  const KecamatanCard({
    super.key,
    required this.data,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.awalTerbuka = false,
  });

  @override
  State<KecamatanCard> createState() => _KecamatanCardState();
}

class _KecamatanCardState extends State<KecamatanCard> {
  late bool _terbuka;

  @override
  void initState() {
    super.initState();
    _terbuka = widget.awalTerbuka;
  }

  void _copyData(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.data.toClipboardText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data disalin ke clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.data;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _terbuka = !_terbuka),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.isReferensi ? Icons.mosque_rounded : Icons.location_on_rounded,
                      size: 18,
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.kecamatan,
                                style: AppTypography.bodyLg(
                                  color: isDark ? AppColors.textDark : AppColors.textLight,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (data.isReferensi) _badgeTerverifikasi(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [data.kabupaten, data.provinsi].where((e) => e != null).join(', '),
                          style: AppTypography.bodyMd(color: Colors.grey.shade500).copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _terbuka ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _terbuka ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kotakKoordinat(
                        isDark: isDark,
                        judul: 'Derajat Desimal',
                        icon: Icons.my_location_rounded,
                        kiriLabel: 'Lintang', kiriNilai: '${data.lat}°',
                        kananLabel: 'Bujur', kananNilai: '${data.lng}°',
                      ),
                      if (data.latDms != null && data.lngDms != null) ...[
                        const SizedBox(height: 8),
                        _kotakKoordinat(
                          isDark: isDark,
                          judul: 'Format DMS',
                          icon: Icons.public_rounded,
                          kiriLabel: 'Lintang', kiriNilai: data.latDms!,
                          kananLabel: 'Bujur', kananNilai: data.lngDms!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onTap,
                              icon: const Icon(Icons.calculate_rounded, size: 17),
                              label: const Text('Lihat Jadwal Sholat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _iconButtonKotak(
                            icon: Icons.copy_rounded,
                            onTap: () => _copyData(context),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _iconButtonKotak(
                            icon: widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            iconColor: widget.isFavorite ? Colors.redAccent : null,
                            onTap: widget.onToggleFavorite,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeTerverifikasi() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.85),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text('Terverifikasi', style: AppTypography.labelCaps(color: AppColors.emeraldDark).copyWith(fontSize: 9.5)),
    );
  }

  Widget _kotakKoordinat({
    required bool isDark,
    required String judul,
    required IconData icon,
    required String kiriLabel,
    required String kiriNilai,
    required String kananLabel,
    required String kananNilai,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.025),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.emerald),
              const SizedBox(width: 6),
              Text(judul, style: AppTypography.labelCaps(color: Colors.grey.shade600).copyWith(fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _labelNilai(isDark, kiriLabel, kiriNilai)),
              Expanded(child: _labelNilai(isDark, kananLabel, kananNilai)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelNilai(bool isDark, String label, String nilai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMd(color: Colors.grey.shade500).copyWith(fontSize: 11)),
        Text(nilai, style: AppTypography.dataDisplay(fontSize: 13.5, color: isDark ? AppColors.textDark : AppColors.textLight)),
      ],
    );
  }

  Widget _iconButtonKotak({required IconData icon, required VoidCallback onTap, required bool isDark, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? (isDark ? AppColors.textDark : AppColors.textLight)),
      ),
    );
  }
}
