/// PDF upload page with KISS interface (US01 AC4).
///
/// Simple flow: pick PDF → upload → show progress → navigate to summary.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/core/theme/app_colors.dart';
import 'package:miestudiomarket_ai_app/features/report_ingestion/presentation/widgets/stat_card_widget.dart';

import '../data/report_repository.dart';
import '../domain/report.dart';
import 'report_summary_page.dart';

class ReportUploadPage extends StatefulWidget {
  const ReportUploadPage({super.key});

  @override
  State<ReportUploadPage> createState() => _ReportUploadPageState();
}

class _ReportUploadPageState extends State<ReportUploadPage> {
  final ReportRepository _repository = ReportRepository();

  bool _isUploading = false;
  String? _uploadedReportId;
  String? _selectedFileName;
  String? _errorMessage;
  Future<int>? _totalReportsFuture;

  @override
  void initState() {
    super.initState();
    _totalReportsFuture = _repository.getReportsCount();
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() {
      _isUploading = true;
      _selectedFileName = result.files.single.name;
      _errorMessage = null;
    });

    try {
      final reportId = await _repository.uploadReport(File(filePath));
      setState(() {
        _uploadedReportId = reportId;
        _isUploading = false;
        // Refresh total analyses properly without fetching all records
        _totalReportsFuture = _repository.getReportsCount();
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error al subir el archivo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ingesta de Reportes')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 250,
                child: _buildQuickStats(),
              ),
              // Header
              Text(
                'Cargar Reporte de Mercado',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sube un PDF para obtener un resumen ejecutivo con análisis de impacto local.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Upload area
              _buildUploadArea(theme),
              const SizedBox(height: 32),

              // Recent Files / Status & Actions
              if (_errorMessage != null) _buildErrorCard(theme),
              if (_uploadedReportId != null) _buildReportStatusSection(),

              // Render the recent files list
              SizedBox(
                width: double.infinity,
                height: 400,
                child: _buildRecentFiles(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(ThemeData theme) {
    return Card(
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: AppColors.primary, width: 3.0),
        ),
        alignment: Alignment.center,
        child: InkWell(
          onTap: _isUploading ? null : _pickAndUploadPdf,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Subiendo $_selectedFileName...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ] else ...[
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.secondaryContainer,
                    child: Icon(
                      Icons.upload_file,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName ?? 'Seleccionar archivo PDF',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca para elegir un reporte',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    label: Text('Subir'),
                    icon: Icon(Icons.upload_file),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStatusSection() {
    return StreamBuilder<Report>(
      stream: _repository.watchReport(_uploadedReportId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final report = snapshot.data;
        if (report == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusIndicator(report.status),
            const SizedBox(height: 16),
            if (report.status == ReportStatus.completed)
              FilledButton.icon(
                onPressed: () => _navigateToSummary(report),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar Resumen'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicator(ReportStatus status) {
    final theme = Theme.of(context);

    final (icon, label, color) = switch (status) {
      ReportStatus.uploading => (
        Icons.cloud_upload,
        'Subiendo archivo...',
        theme.colorScheme.primary,
      ),
      ReportStatus.processing => (
        Icons.auto_fix_high,
        'Procesando con IA...',
        theme.colorScheme.tertiary,
      ),
      ReportStatus.completed => (
        Icons.check_circle,
        'Listo para analizar',
        Colors.green,
      ),
      ReportStatus.failed => (
        Icons.error,
        'Error en el procesamiento',
        theme.colorScheme.error,
      ),
    };

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: Text('Archivo: $_selectedFileName'),
        trailing: status == ReportStatus.processing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }

  void _navigateToSummary(Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportSummaryPage(report: report)),
    );
  }

  Widget _buildQuickStats() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Cuota Almacenamiento
          SizedBox(
            width: 180,
            child: StatCardWidget(
              title: 'CUOTA\nALMACENAMIENTO',
              value: '72%',
              subtitle: '/ 10GB',
              backgroundColor: theme.colorScheme.primary,
              titleColor: theme.colorScheme.onPrimaryContainer,
              valueColor: theme.colorScheme.onPrimary,
              subtitleColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          // Card 2: Tiempo de Respuesta
          SizedBox(
            width: 180,
            child: StatCardWidget(
              title: 'TIEMPO DE RESPUESTA',
              value: '1.2s',
              subtitle: 'Optimizado por Gemini Flash 2.5',
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              titleColor: theme.colorScheme.onSurfaceVariant,
              valueColor: theme.colorScheme.primary,
              subtitleColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          // Card 3: Total de Análisis
          FutureBuilder<int>(
            future: _totalReportsFuture,
            builder: (context, snapshot) {
              final displayValue = snapshot.hasData
                  ? snapshot.data.toString()
                  : '...';
              return SizedBox(
                width: 180,
                child: StatCardWidget(
                  title: 'TOTAL DE ANÁLISIS',
                  value: displayValue,
                  subtitle: '+12% vs mes anterior',
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  titleColor: theme.colorScheme.onSurfaceVariant,
                  valueColor: theme.colorScheme.primary,
                  subtitleColor: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFiles(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Documentos Recientes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary, // #00193c
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '30d',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, // #43474f
                  letterSpacing: 1.2,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Report>>(
            stream: _repository.watchAllReports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error cargando documentos: ${snapshot.error}'),
                );
              }
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return Center(
                  child: Text(
                    'No hay documentos recientes.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }

              return ListView.separated(
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildRecentFileItem(theme, reports[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFileItem(ThemeData theme, Report report) {
    final String formattedDate = _formatDate(report.uploadedAt);

    // Status Badge Logic
    Color badgeColor;
    String badgeText;
    switch (report.status) {
      case ReportStatus.completed:
        badgeColor = const Color(0xFF83FBA5); // Green dot
        badgeText = 'Procesado';
        break;
      case ReportStatus.processing:
        badgeColor = const Color(0xFFF59E0B); // Amber dot
        badgeText = 'En Progreso';
        break;
      case ReportStatus.uploading:
        badgeColor = const Color(0xFFF59E0B); // Amber dot
        badgeText = 'Subiendo...';
        break;
      case ReportStatus.failed:
        badgeColor = const Color(0xFFBA1A1A); // Red dot
        badgeText = 'Error';
        break;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceBright, // #f9f9fc
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: report.status == ReportStatus.completed
            ? () => _navigateToSummary(report)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Icon wrapped in primary transparent box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(
                    25,
                  ), // ~10% opacity rgba(0,45,98,0.1)
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    Icons.insert_drive_file_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        report.fileName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          height: 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(
                          226,
                          226,
                          229,
                          0.6,
                        ), // Translucent backdrop
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            badgeText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC4C6D1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PDF', // Placeholder for size since it's not in the model
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron / Action Icon
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
