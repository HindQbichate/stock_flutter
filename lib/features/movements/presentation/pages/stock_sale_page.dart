import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_flutter/core/theme/app_theme.dart';
import 'package:stock_flutter/features/movements/data/models/movement_model.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/presentation/providers/product_provider.dart';
import 'package:stock_flutter/shared/widgets/app_text_field.dart';
import 'package:stock_flutter/shared/widgets/loading_button.dart';

class StockSalePage extends ConsumerStatefulWidget {
  const StockSalePage({super.key});

  @override
  ConsumerState<StockSalePage> createState() => _StockSalePageState();
}

class _StockSalePageState extends ConsumerState<StockSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();

  ProductEntity? _selectedProduct;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onProductSelected(ProductEntity? p) {
    setState(() {
      _selectedProduct = p;
      if (p != null) {
        _priceController.text = p.price.toStringAsFixed(2);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un produit')),
      );
      return;
    }

    final qty = int.parse(_quantityController.text);
    if (qty > (_selectedProduct?.quantity ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stock insuffisant. Disponible: ${_selectedProduct!.quantity}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(movementNotifierProvider.notifier).createSale(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          productSku: _selectedProduct!.sku,
          quantity: qty,
          unitPrice: double.tryParse(_priceController.text),
          note: _noteController.text.trim(),
        );

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente enregistrée avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final error = ref.read(movementNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsStreamProvider).valueOrNull ?? [];
    final availableProducts = products.where((p) => !p.isOutOfStock).toList();
    final isLoading = ref.watch(movementNotifierProvider).isLoading;

    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final total = qty * price;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectuer une vente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Sortie de stock — Vente',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product selector
              Text('Produit *',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProductEntity>(
                value: _selectedProduct,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.inventory_2_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                hint: const Text('Sélectionner un produit'),
                items: availableProducts
                    .map(
                      (p) => DropdownMenuItem<ProductEntity>(
                        value: p,
                        child: Text(
                          '${p.name} (dispo: ${p.quantity})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onProductSelected,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _quantityController,
                label: 'Quantité vendue *',
                hint: 'Ex: 3',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Quantité invalide';
                  if (_selectedProduct != null && n > _selectedProduct!.quantity) {
                    return 'Stock insuffisant (max: ${_selectedProduct!.quantity})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _priceController,
                label: 'Prix unitaire de vente (DH)',
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.sell_outlined,
              ),

              // Total preview
              if (total > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total vente :',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${total.toStringAsFixed(2)} DH',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              AppTextField(
                controller: _noteController,
                label: 'Note / Référence client',
                hint: 'Optionnel',
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              LoadingButton(
                onPressed: _submit,
                isLoading: isLoading,
                label: 'Confirmer la vente',
                icon: Icons.check_rounded,
                backgroundColor: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
