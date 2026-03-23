/// Main page for US02 — Market Gaps Detection.
///
/// Shows competitor catalog, triggers gap analysis, and displays
/// results via scatter chart and buyer persona cards.
library;

import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/core/theme/app_colors.dart';

import '../../report_ingestion/data/report_repository.dart';
import '../../report_ingestion/domain/report.dart';
import '../data/market_gaps_repository.dart';
import '../domain/competitor.dart';
import '../domain/market_gap.dart';
import 'add_competitor_dialog.dart';
import 'buyer_persona_card.dart';
import 'market_gap_chart.dart';

class MarketGapsPage extends StatefulWidget {
  const MarketGapsPage({super.key});

  @override
  State<MarketGapsPage> createState() => _MarketGapsPageState();
}

class _MarketGapsPageState extends State<MarketGapsPage> {
  final MarketGapsRepository _gapsRepo = MarketGapsRepository();
  final ReportRepository _reportRepo = ReportRepository();

  List<MarketGap> _gaps = [];
  bool _isAnalyzing = false;
  String? _selectedReportId;
  String? _errorMessage;

  Future<void> _runAnalysis() async {
    if (_selectedReportId == null) {
      setState(() => _errorMessage = 'Selecciona un reporte primero');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final gaps = await _gapsRepo.analyzeGaps(reportId: _selectedReportId!);
      setState(() {
        _gaps = gaps;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Error en el análisis: $e';
      });
    }
  }

  Future<void> _showAddCompetitorDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddCompetitorDialog(),
    );

    if (result == null) return;

    try {
      await _gapsRepo.addCompetitor(
        name: result['name'] as String,
        category: result['category'] as String,
        products: result['products'] as List<String>,
        location: result['location'] as String,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar competidor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección de Nichos'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_business),
        //     tooltip: 'Agregar Competidor',
        //     onPressed: _showAddCompetitorDialog,
        //   ),
        // ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Report selector
          _buildReportSelector(theme),
          const SizedBox(height: 16),

          // Competitor catalog
          Expanded(child: _buildCompetitorSection(theme)),
          const SizedBox(height: 20),

          // Analyze button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isAnalyzing ? null : _runAnalysis,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: Text(
                _isAnalyzing ? 'Analizando con IA...' : 'Detectar Nichos',
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error
          if (_errorMessage != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),

          // Results
          if (_gaps.isNotEmpty) ...[
            MarketGapChart(gaps: _gaps),
            const SizedBox(height: 16),
            Text('Nichos Identificados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._gaps.map(
              (gap) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BuyerPersonaCard(gap: gap),
              ),
            ),
          ],
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildReportSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 3,),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seleccionar Reporte', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          StreamBuilder<List<Report>>(
            stream: _reportRepo.watchAllReports(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
      
              final reports = snapshot.data!
                  .where((r) => r.status == ReportStatus.completed)
                  .toList();
      
              if (reports.isEmpty) {
                return const Text('No hay reportes procesados aún');
              }
      
              return DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedReportId,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(18.0),),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(18.0),)
                  ),
                  border: OutlineInputBorder(),
                  hintText: 'Elige un reporte',
                ),
                items: reports
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          r.fileName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedReportId = value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorSection(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Catálogo de Competidores', style: theme.textTheme.titleSmall),
            TextButton.icon(
              onPressed: _showAddCompetitorDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Competitor>>(
          stream: _gapsRepo.watchCompetitors(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final competitors = snapshot.data!;
            if (competitors.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Agrega competidores locales para el análisis'),
              );
            }

            return ListView.separated(
              itemCount: competitors.length,
              scrollDirection: Axis.vertical,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              clipBehavior: Clip.none,
              separatorBuilder: (context, index) => SizedBox(height: 10,),
              itemBuilder: (context, index) {
                final competitor = competitors[index];
                return ListTile(
                  tileColor: AppColors.primaryFixed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.all(Radius.circular(12))
                  ),
                  dense: true,
                  leading: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.primaryContainer,),
                  title: Text(
                    competitor.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${competitor.category} · ${competitor.products.length} productos',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _gapsRepo.deleteCompetitor(competitor.id),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
