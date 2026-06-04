import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_flutter/core/theme/app_theme.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/categories/data/repositories/category_repository_impl.dart';
import 'package:stock_flutter/features/categories/domain/entities/category_entity.dart';
import 'package:stock_flutter/features/products/data/models/product_model.dart';
import 'package:stock_flutter/features/products/presentation/providers/product_provider.dart';
import 'package:stock_flutter/shared/widgets/app_text_field.dart';
import 'package:stock_flutter/shared/widgets/loading_button.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormPage({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  CategoryEntity? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    final tenantId = ref.read(currentTenantIdProvider) ?? '';
    final product = ProductModel(
      id: widget.productId ?? '',
      tenantId: tenantId,
      name: _nameController.text.trim(),
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      sku: _skuController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 0,
      threshold: int.tryParse(_thresholdController.text) ?? 5,
      price: double.tryParse(_priceController.text) ?? 0,
      description: _descController.text.trim(),
      createdAt: DateTime.now(),
    );

    bool success;
    if (widget.isEditing) {
      success = await ref
          .read(productNotifierProvider.notifier)
          .updateProduct(product);
    } else {
      success = await ref
          .read(productNotifierProvider.notifier)
          .createProduct(product);
    }

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Produit mis à jour' : 'Produit créé avec succès',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final error = ref.read(productNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Erreur lors de la sauvegarde'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final isLoading = ref.watch(productNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier produit' : 'Nouveau produit'),
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
              _sectionTitle(context, 'Informations générales'),
              const SizedBox(height: 12),

              AppTextField(
                controller: _nameController,
                label: 'Nom du produit *',
                hint: 'Ex: Chemise bleue XL',
                prefixIcon: Icons.label_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _skuController,
                label: 'SKU / Référence',
                hint: 'Ex: CH-BLEU-XL',
                prefixIcon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Description optionnelle...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              _sectionTitle(context, 'Catégorie'),
              const SizedBox(height: 12),

              // Category selector with inline creation
              _CategorySelector(
                categories: categories,
                selected: _selectedCategory,
                onSelected: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),

              const SizedBox(height: 20),
              _sectionTitle(context, 'Stock & Prix'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _quantityController,
                      label: 'Quantité initiale',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.numbers_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (int.tryParse(v) == null) return 'Nombre invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _thresholdController,
                      label: 'Seuil d\'alerte',
                      hint: '5',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.warning_amber_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (int.tryParse(v) == null) return 'Nombre invalide';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _priceController,
                label: 'Prix unitaire (DH)',
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.sell_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (double.tryParse(v) == null) return 'Nombre invalide';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              LoadingButton(
                onPressed: _save,
                isLoading: isLoading,
                label: widget.isEditing ? 'Enregistrer' : 'Créer le produit',
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
          ),
    );
  }
}

// ─── Category Selector Widget ──────────────────────────────────────────────
class _CategorySelector extends ConsumerWidget {
  final List<CategoryEntity> categories;
  final CategoryEntity? selected;
  final void Function(CategoryEntity) onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing categories chips
        if (categories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final isSelected = selected?.id == cat.id;
              return FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (_) => onSelected(cat),
                selectedColor: AppColors.primaryContainer,
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        // Add new category inline
        OutlinedButton.icon(
          onPressed: () => _showAddCategoryDialog(context, ref),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nouvelle catégorie'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom de la catégorie',
            prefixIcon: Icon(Icons.category_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final created = await ref
                  .read(categoryNotifierProvider.notifier)
                  .createCategory(name: name);

              if (created != null) {
                onSelected(created);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
