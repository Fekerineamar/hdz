import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/domain.dart';

/// Represents a catalog certificate service that can be requested with one click.
class CertificateServiceOption {
  final String name;
  final String serviceUnid;
  final String icon;
  final String description;
  final String dept;

  const CertificateServiceOption({
    required this.name,
    required this.serviceUnid,
    required this.icon,
    required this.description,
    required this.dept,
  });
}

/// Popular certificates in Algeria available for instant one-click request.
const List<CertificateServiceOption> popularCertificates = [
  CertificateServiceOption(
    name: 'شهادة الميلاد',
    serviceUnid: '000000200100010000',
    icon: '📜',
    description: 'طلب واستخراج شهادة الميلاد الإلكترونية الرسمية.',
    dept: 'وزارة الداخلية والجماعات المحلية',
  ),
  CertificateServiceOption(
    name: 'وثيقة الإقامة (شهادة / بطاقة)',
    serviceUnid: '000000200100040000',
    icon: '🏠',
    description: 'طلب استخراج شهادة أو بطاقة الإقامة الإلكترونية.',
    dept: 'وزارة الداخلية والجماعات المحلية',
  ),
  CertificateServiceOption(
    name: 'صحيفة السوابق القضائية',
    serviceUnid: '000000200900010000',
    icon: '⚖️',
    description: 'استخراج القسيمة رقم 3 من صحيفة السوابق القضائية (Casier judiciaire).',
    dept: 'وزارة العدل',
  ),
  CertificateServiceOption(
    name: 'شهادة الجنسية الجزائرية',
    serviceUnid: '000000200900020000',
    icon: '🇩🇿',
    description: 'طلب واستخراج شهادة الجنسية الجزائرية عبر الإنترنت.',
    dept: 'وزارة العدل',
  ),
  CertificateServiceOption(
    name: 'شهادة الزواج',
    serviceUnid: '000000200100020000',
    icon: '💍',
    description: 'طلب واستخراج شهادة عقد الزواج الرسمية.',
    dept: 'وزارة الداخلية والجماعات المحلية',
  ),
  CertificateServiceOption(
    name: 'شهادة الانتساب أو عدم الانتساب CNAS',
    serviceUnid: '000000200203010000',
    icon: '🏥',
    description: 'استخراج شهادة الانتساب أو عدم الانتساب للضمان الاجتماعي للعمال الأجراء.',
    dept: 'الصندوق الوطني للضمان الاجتماعي CNAS',
  ),
  CertificateServiceOption(
    name: 'شهادة عدم الانتساب CASNOS',
    serviceUnid: '000000200201020000',
    icon: '💼',
    description: 'شهادة تثبت عدم انتساب الشخص لصندوق غير الأجراء.',
    dept: 'الصندوق الوطني لغير الأجراء CASNOS',
  ),
  CertificateServiceOption(
    name: 'شهادة عدم الخضوع للضريبة',
    serviceUnid: '000000200302020000',
    icon: '📋',
    description: 'شهادة عدم الخضوع للضريبة صادرة من مصالح الضرائب.',
    dept: 'المديرية العامة للضرائب',
  ),
  CertificateServiceOption(
    name: 'شهادة الترقيم الجبائي NIF',
    serviceUnid: '000000200302040000',
    icon: '🔢',
    description: 'استخراج شهادة رقم التعريف الجبائي للشخص الطبيعي.',
    dept: 'المديرية العامة للضرائب',
  ),
  CertificateServiceOption(
    name: 'شهادة الوفاة',
    serviceUnid: '000000200100030000',
    icon: '📄',
    description: 'طلب واستخراج شهادة الوفاة الرسمية.',
    dept: 'وزارة الداخلية والجماعات المحلية',
  ),
];

/// Screen showing existing certificates and one-click request menu.
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({
    super.key,
    required this.certificates,
    this.onRequestCertificate,
  });

  final List<Certificate> certificates;
  final void Function(String name, String unid)? onRequestCertificate;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الشهادات والوثائق الإلكترونية'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.flash_on_rounded), text: 'طلب شهادة بنقرة واحدة'),
              Tab(icon: Icon(Icons.folder_shared_rounded), text: 'شهاداتي الصادرة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Request a new certificate in 1 click
            _RequestNewCertificatesView(
              onRequest: (name, unid) {
                Navigator.of(context).pop();
                onRequestCertificate?.call(name, unid);
              },
            ),
            // Tab 2: Existing issued certificates
            _IssuedCertificatesView(certificates: certificates),
          ],
        ),
      ),
    );
  }
}

class _RequestNewCertificatesView extends StatelessWidget {
  const _RequestNewCertificatesView({required this.onRequest});
  final void Function(String name, String unid) onRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: popularCertificates.length,
      itemBuilder: (context, i) {
        final item = popularCertificates[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.dept,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('طلب', style: TextStyle(fontSize: 12)),
                  onPressed: () => onRequest(item.name, item.serviceUnid),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IssuedCertificatesView extends StatelessWidget {
  const _IssuedCertificatesView({required this.certificates});
  final List<Certificate> certificates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: scheme.outlineVariant),
            const SizedBox(height: 12),
            Text('لا توجد شهادات صادرة حالياً', style: TextStyle(color: scheme.outline)),
            const SizedBox(height: 8),
            Text(
              'يمكنك طلب شهادة جديدة بنقرة واحدة من التبويب أعلاه.',
              style: TextStyle(fontSize: 12, color: scheme.outline.withOpacity(0.8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: certificates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CertCard(cert: certificates[i]),
    );
  }
}

class _CertCard extends StatelessWidget {
  const _CertCard({required this.cert});
  final Certificate cert;

  Color _stateColor(BuildContext context) {
    final s = cert.state.toLowerCase();
    if (s.contains('valid') || s.contains('active') || s.contains('فعال')) {
      return Colors.green;
    } else if (s.contains('expire') || s.contains('منته')) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stateColor = _stateColor(context);
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cert.state.isEmpty ? 'غير محدد' : cert.state,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stateColor,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'نسخ رقم الشهادة',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cert.licenseNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم النسخ'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cert.licenseName.isEmpty ? cert.licenseType : cert.licenseName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (cert.holder.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(cert.holder, style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (cert.licenseNumber.isNotEmpty)
                  _InfoChip(icon: Icons.tag, label: cert.licenseNumber),
                if (cert.issueDate.isNotEmpty)
                  _InfoChip(icon: Icons.calendar_today_outlined, label: 'صدر: ${cert.issueDate}'),
                if (cert.validTimeEnd.isNotEmpty)
                  _InfoChip(icon: Icons.event_available_outlined, label: 'ينتهي: ${cert.validTimeEnd}'),
                if (cert.dept.isNotEmpty)
                  _InfoChip(icon: Icons.account_balance_outlined, label: cert.dept),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: scheme.outline),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.7))),
      ],
    );
  }
}
