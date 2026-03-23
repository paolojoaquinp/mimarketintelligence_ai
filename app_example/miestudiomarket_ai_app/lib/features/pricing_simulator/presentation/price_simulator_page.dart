import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/core/theme/app_colors.dart';

import '../data/pricing_repository.dart';
import '../domain/commodity_feed.dart';
import '../domain/price_simulation_result.dart';
import 'comparative_table.dart';
import 'margin_traffic_light.dart';

/// Main page for the Market Price Simulator (US03).
class PriceSimulatorPage extends StatefulWidget {
  const PriceSimulatorPage({super.key});

  @override
  State<PriceSimulatorPage> createState() => _PriceSimulatorPageState();
}

class _PriceSimulatorPageState extends State<PriceSimulatorPage> {
  final PricingRepository _repository = PricingRepository();

  bool _isLoadingFeed = true;
  bool _isSimulating = false;
  String? _errorMessage;

  CommodityFeed? _feed;
  Commodity? _selectedCommodity;
  double _userSalePrice = 0.0;
  
  PriceSimulationResult? _simulationResult;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final feed = await _repository.getCommodityPrices();
      setState(() {
        _feed = feed;
        if (feed.commodities.isNotEmpty) {
          _selectedCommodity = feed.commodities.first;
          // Set an arbitrary default sale price slightly above cost
          _userSalePrice = _selectedCommodity!.price * 1.5;
        }
        _isLoadingFeed = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando feed de precios: $e';
        _isLoadingFeed = false;
      });
    }
  }

  Future<void> _runSimulation() async {
    if (_selectedCommodity == null) return;

    setState(() {
      _isSimulating = true;
      _errorMessage = null;
      _simulationResult = null;
    });

    try {
      final result = await _repository.simulatePrices(
        productName: _selectedCommodity!.name,
        userBaseCost: _selectedCommodity!.price,
        userSalePrice: _userSalePrice,
      );
      setState(() {
        _simulationResult = result;
        _isSimulating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en simulación: $e';
        _isSimulating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Precios'),
        actions: [
          if (_simulationResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _simulationResult = null);
              },
            )
        ],
      ),
      body: _isLoadingFeed
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Optimiza tu Margen de Ganancia',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compara tu costo de producción con los precios promedio del mercado reportados por la herramienta de IA.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) _buildErrorCard(theme),
                    
                    // Inputs
                    if (_feed != null && _simulationResult == null)
                      _buildConfigurationSection(theme),
            
                    // Results
                    if (_isSimulating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Consultando IA de Mercado...'),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_simulationResult != null) ...[
                      MarginTrafficLightWidget(
                        trafficLight: _simulationResult!.trafficLight,
                        marginPercentage: _simulationResult!.marginPercentage,
                      ),
                      const SizedBox(height: 24),
                      ComparativeTable(result: _simulationResult!),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _simulationResult = null),
                        icon: const Icon(Icons.edit),
                        label: const Text('Ajustar Precios'),
                      )
                    ],
                    const SizedBox(height: 200,),
                  ],
                ),
            ),
          ),
    );
  }

  Widget _buildConfigurationSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary,width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('1. Insumo Base', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<Commodity>(
              isExpanded: true,
              initialValue: _selectedCommodity,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0),),
                  
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0),),
                  borderSide: BorderSide(color: AppColors.primary,width: 2),
                ),
                labelText: 'Materia Prima',
              ),
              items: _feed!.commodities.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text('${c.name} (Costo: \$${c.price}/${c.unit})'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCommodity = val;
                    _userSalePrice = val.price * 1.5; // Reset slider roughly
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            Text('2. Tu Precio de Venta', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '\$${_userSalePrice.toStringAsFixed(2)}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Slider(
              value: _userSalePrice,
              min: _selectedCommodity!.price, // Can't sell below cost
              max: _selectedCommodity!.price * 4,
              divisions: 30,
              label: '\$${_userSalePrice.toStringAsFixed(2)}',
              onChanged: (val) {
                setState(() => _userSalePrice = val);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _runSimulation,
              icon: const Icon(Icons.analytics),
              label: const Text('Analizar Rentabilidad'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 24),
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
}
