/// Report summary display page using Gemini Chat UI.
///
/// Shows the generated executive summary, "Impacto Local" section (US01 AC2),
/// and source citations (US01 AC3) inside a conversational interface.
library;

import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/core/theme/app_colors.dart';

import '../data/report_repository.dart';
import '../domain/analysis_result.dart';
import '../domain/report.dart';

import 'widgets/gemini_header.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/chat_input_area.dart';
import 'widgets/agent_loading_dots.dart';

class ChatMessage {
  final bool isUser;
  final Widget content;
  final String? attachmentName;
  final String time;

  ChatMessage({
    required this.isUser,
    required this.content,
    this.attachmentName,
    required this.time,
  });
}

class ReportSummaryPage extends StatefulWidget {
  final Report report;

  const ReportSummaryPage({super.key, required this.report});

  @override
  State<ReportSummaryPage> createState() => _ReportSummaryPageState();
}

class _ReportSummaryPageState extends State<ReportSummaryPage> {
  final ReportRepository _repository = ReportRepository();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial greeting from AI based on Figma
    _messages.add(
      ChatMessage(
        isUser: false,
        content: const Text(
          'He analizado el documento de forma exitosa. He identificado puntos clave del mercado. ¿En qué aspecto específico de los datos deseas profundizar?',
        ),
        attachmentName: widget.report.fileName,
        time: _formatTime(DateTime.now()),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _generateSummary() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    final now = DateTime.now();

    setState(() {
      _messages.add(
        ChatMessage(
          isUser: true,
          content: Text(query),
          time: '${_formatTime(now)} · Entregado',
        ),
      );
      _queryController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final result = await _repository.generateSummary(
        reportId: widget.report.id,
        query: query,
      );

      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            content: _buildResultContent(result),
            time: _formatTime(DateTime.now()),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            isUser: false,
            content: Text(
              'Error al realizar la consulta:\n$e',
              style: const TextStyle(color: Colors.red),
            ),
            time: _formatTime(DateTime.now()),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Widget _buildResultContent(AnalysisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(result.summary),
        const SizedBox(height: 16),
        const Text(
          'Impacto Local:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF00193C),
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(result.localImpact),
        if (result.citations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Fuentes:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF00193C),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.citations.map((c) {
              return ActionChip(
                padding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF556474),
                ),
                backgroundColor: const Color(0xFFF3F3F6),
                side: BorderSide.none,
                label: Text('Pág. ${c.page}, §${c.paragraph}'),
                onPressed: () => _showCitationDetail(context, c),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showCitationDetail(BuildContext context, SourceRef citation) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de Fuente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow('Archivo', citation.fileName),
            _detailRow('Página', '${citation.page}'),
            _detailRow('Párrafo', '${citation.paragraph}'),
            _detailRow('Hash', citation.fileHash.substring(0, 12)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F9FC,
      ), // Background shown in Figma usually slightly off-white
      appBar: AppBar(
        backgroundColor: AppColors.secondary.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00193C)),
        title: Column(
          children: [
            Text(
              'Agente',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -1.2,
              ),
            ),
            Text(
              'Analista de mercado',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GeminiHeaderWidget(fileName: widget.report.fileName),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return ChatBubbleWidget(
                    isUser: msg.isUser,
                    content: msg.content,
                    time: msg.time,
                    attachmentName: msg.attachmentName,
                  );
                },
              ),
            ),
            if (_isLoading) AgentLoadingDots(),
            Padding(
              padding: const EdgeInsets.only(left: 24.0, bottom: 16.0),
              child: QuickActionsRowWidget(
                actions: const [
                  'Resumir puntos clave',
                  'Analizar riesgos',
                  'FODA del mercado',
                ],
                onActionSelected: (val) {
                  _queryController.text = val;
                  _generateSummary();
                },
              ),
            ),
            ChatInputAreaWidget(
              controller: _queryController,
              isLoading: _isLoading,
              onSend: _generateSummary,
            ),
          ],
        ),
      ),
    );
  }
}
