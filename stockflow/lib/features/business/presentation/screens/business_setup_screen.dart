import 'package:flutter/material.dart';
import '../../../../core/widgets/local_image_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/business_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _logoPath;
  bool _isLoading = false;
  bool _isEditing = false;
  BusinessesData? _existingBusiness;

  @override
  void initState() {
    super.initState();
    _loadExistingBusiness();
  }

  Future<void> _loadExistingBusiness() async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId != -1) {
      final repo = ref.read(businessRepositoryProvider);
      final business = await repo.getActiveBusiness();
      if (business != null && mounted) {
        setState(() {
          _existingBusiness = business;
          _isEditing = true;
          _nameCtrl.text = business.name;
          _ownerCtrl.text = business.ownerName;
          _phoneCtrl.text = business.phone;
          _emailCtrl.text = business.email ?? '';
          _addressCtrl.text = business.address ?? '';
          _logoPath = business.logoPath;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _logoPath = file.path);
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(businessRepositoryProvider);

      if (_isEditing && _existingBusiness != null) {
        final updated = _existingBusiness!.copyWith(
          name: _nameCtrl.text.trim(),
          ownerName: _ownerCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: Value(_emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim()),
          address: Value(_addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim()),
          logoPath: Value(_logoPath),
        );
        await repo.updateBusiness(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business details updated successfully!')),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile');
          }
        }
        return;
      }

      final businessId = await repo.createBusiness(
        name: _nameCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        logoPath: _logoPath,
        businessType: 'General', // Will be set on next screen
      );

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt(AppConstants.keyBusinessId, businessId);

      ref.read(activeBusinessIdProvider.notifier).state = businessId;

      if (mounted) context.go('/business-type');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Business Details' : 'Business Setup'),
        automaticallyImplyLeading: _isEditing,
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing) ...[
                _StepIndicator(current: 1, total: 3),
                const SizedBox(height: 24),
                Text(
                  'Tell us about your business',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This information will appear on your reports and invoices',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
              ] else ...[
                Text(
                  'Update your business details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Make changes to your store information, owner name, or contact details',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
              ],

              // Logo picker
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: _logoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LocalImageRenderer(
                              imagePath: _logoPath!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 32, color: cs.onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text('Add Logo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: cs.onSurfaceVariant)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              AppTextField(
                controller: _nameCtrl,
                label: 'Business Name *',
                prefixIcon: const Icon(Icons.business_outlined),
                validator: (v) => AppValidators.required(v, 'Business name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _ownerCtrl,
                label: 'Owner Name *',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => AppValidators.required(v, 'Owner name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneCtrl,
                label: 'Phone Number *',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: AppValidators.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email (Optional)',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressCtrl,
                label: 'Address (Optional)',
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              if (_isEditing && _existingBusiness != null) ...[
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.storefront_outlined, color: cs.primary),
                    title: const Text('Business Category / Type', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Current: ${_existingBusiness!.businessType}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/business-type'),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isEditing ? 'Save Changes' : 'Continue',
                  icon: _isEditing ? Icons.check : Icons.arrow_forward,
                  onPressed: _continue,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done || active ? cs.primary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
