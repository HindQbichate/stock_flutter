import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_flutter/core/theme/app_theme.dart';
import 'package:stock_flutter/features/movements/data/models/movement_model.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/presentation/providers/product_provider.dart';
import 'package:stock_flutter/shared/widgets/app_text_field.dart';
import 'package:stock_flutter/shared/widgets/loading_button.dart';

class StockEntryPage extends ConsumerStatefulWidget {
  const StockEntryPage({super.key});

  @override
  ConsumerState<StockEntryPage> createState() => _StockEntryPageState();
}

class _StockEntryPageState extends ConsumerState<StockEntryPage> {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un produit')),
      );
      return;
    }

    final success = await ref.read(movementNotifierProvider.notifier).createEntry(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          productSku: _selectedProduct!.sku,
          quantity: int.parse(_quantityController.text),
          unitPrice: double.tryParse(_priceController.text),
          note: _noteController.text.trim(),
        );

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrée en stock enregistrée'),
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
    final isLoading = ref.watch(movementNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrée en stock'),
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
              // Movement type indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded,
                        color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Réception de marchandises',
                      style: TextStyle(
                        color: AppColors.success,
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
              _ProductDropdown(
                products: products,
                selected: _selectedProduct,
                onChanged: (p) => setState(() => _selectedProduct = p),
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Stock actuel: ${_selectedProduct!.quantity} unités',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              AppTextField(
                controller: _quantityController,
                label: 'Quantité reçue *',
                hint: 'Ex: 50',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Quantité invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _priceController,
                label: 'Prix unitaire d\'achat (DH)',
                hint: 'Optionnel',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.sell_outlined,
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _noteController,
                label: 'Note / Référence fournisseur',
                hint: 'Optionnel',
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              LoadingButton(
                onPressed: _submit,
                isLoading: isLoading,
                label: 'Confirmer l\'entrée',
                icon: Icons.check_rounded,
                backgroundColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDropdown extends StatelessWidget {
  final List<ProductEntity> products;
  final ProductEntity? selected;
  final void Function(ProductEntity?) onChanged;

  const _ProductDropdown({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProductEntity>(
      value: selected,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: const Text('Sélectionner un produit'),
      items: products
          .map(
            (p) => DropdownMenuItem<ProductEntity>(
              value: p,
              child: Text('${p.name} (${p.sku})',
                  overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
