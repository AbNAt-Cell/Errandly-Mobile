import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../main.dart';
import 'errand_detail_screen.dart';

class CreateErrandScreen extends StatefulWidget {
  const CreateErrandScreen({super.key});

  @override
  State<CreateErrandScreen> createState() => _CreateErrandScreenState();
}

class _CreateErrandScreenState extends State<CreateErrandScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;

  // Step 1 — Task info
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _itemDetailsCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();
  String _category = 'grocery_purchase';
  String _urgency = 'standard';

  // Step 2 — Locations
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();

  // Step 3 — Budget
  int _budget = 2000;
  int get _platformFee => (_budget * 0.15).ceil();
  int get _total => _budget + _platformFee;

  final List<String> _stepTitles = ['Task Info', 'Locations', 'Budget', 'Review'];

  Future<void> _submitErrand() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.createErrand({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'urgency': _urgency,
        'pickup_address': _pickupCtrl.text.trim(),
        'pickup_latitude': AppConstants.defaultLat,
        'pickup_longitude': AppConstants.defaultLng,
        'destination_address': _destCtrl.text.trim(),
        'destination_latitude': AppConstants.defaultLat + 0.01,
        'destination_longitude': AppConstants.defaultLng + 0.01,
        'recipient_name': _recipientNameCtrl.text.trim(),
        'recipient_phone': _recipientPhoneCtrl.text.trim(),
        'item_details': _itemDetailsCtrl.text.trim(),
        'special_instructions': _specialCtrl.text.trim(),
        'budget': _budget,
      });

      if (mounted) {
        final publicId = response.data['errand']['public_id'] as String;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandPublicId: publicId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Post Errand'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: colorScheme.outlineVariant,
            color: colorScheme.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: i <= _step ? colorScheme.primary : colorScheme.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text('${i + 1}', style: TextStyle(color: i <= _step ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w700))),
                      ),
                      if (i < 3) Expanded(child: Container(height: 3, color: i < _step ? colorScheme.primary : colorScheme.surfaceVariant)),
                    ],
                  ),
                )),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStep(theme, colorScheme),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface, 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () {
                          if (_step < 3) {
                            setState(() => _step++);
                          } else {
                            _submitErrand();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: _loading
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
                            : Text(_step < 3 ? 'Continue' : 'Post Errand & Pay ₦$_total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, ColorScheme colorScheme) {
    return switch (_step) {
      0 => _buildStep1(theme, colorScheme),
      1 => _buildStep2(theme, colorScheme),
      2 => _buildStep3(theme, colorScheme),
      3 => _buildStep4(theme, colorScheme),
      _ => const SizedBox(),
    };
  }

  Widget _buildStep1(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What do you need done?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'Task Title', 
            hintText: 'e.g. Pick up my medicine',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _CategoryPicker(colorScheme),
        const SizedBox(height: 20),
        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description', 
            hintText: 'Describe exactly what you need done...', 
            alignLabelWithHint: true,
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (v) => ((v?.length ?? 0) < 10) ? 'Describe in more detail' : null,
        ),
        const SizedBox(height: 24),
        Text('Urgency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _urgencyChip('standard', '🕐 Standard', colorScheme),
            _urgencyChip('urgent', '⚡ Urgent', colorScheme),
            _urgencyChip('scheduled', '📅 Scheduled', colorScheme),
          ],
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _itemDetailsCtrl, 
          maxLines: 2, 
          decoration: InputDecoration(
            labelText: 'Item Details (optional)', 
            hintText: 'List items, quantities, brands...',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          )
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where and to whom?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _pickupCtrl,
          decoration: InputDecoration(
            labelText: 'Pickup Address', 
            hintText: 'e.g. 12 Udo Udoma Ave, Uyo...', 
            prefixIcon: Icon(Icons.radio_button_on, color: colorScheme.primary),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _destCtrl,
          decoration: InputDecoration(
            labelText: 'Destination', 
            hintText: '4 Adeola Odeku St, VI...', 
            prefixIcon: Icon(Icons.location_on_rounded, color: colorScheme.error),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _recipientNameCtrl, 
          decoration: InputDecoration(
            labelText: 'Recipient Name (optional)', 
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          )
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _recipientPhoneCtrl, 
          keyboardType: TextInputType.phone, 
          decoration: InputDecoration(
            labelText: 'Recipient Phone (optional)', 
            prefixIcon: const Icon(Icons.phone_outlined),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          )
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _specialCtrl, 
          maxLines: 2, 
          decoration: InputDecoration(
            labelText: 'Special Instructions (optional)',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          )
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set your budget', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text('The runner earns 100% of your budget. Platform fee is added on top.', style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            children: [
              Text('₦$_budget', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: colorScheme.primary)),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceVariant,
                  thumbColor: colorScheme.primary,
                  overlayColor: colorScheme.primary.withOpacity(0.2),
                ),
                child: Slider(
                  value: _budget.toDouble(),
                  min: 500, max: 50000,
                  divisions: 99,
                  onChanged: (v) => setState(() => _budget = v.round()),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [1000, 2000, 3500, 5000, 10000].map((amount) => GestureDetector(
                  onTap: () => setState(() => _budget = amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _budget == amount ? colorScheme.primary.withOpacity(0.1) : colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _budget == amount ? colorScheme.primary : Colors.transparent),
                    ),
                    child: Text('₦$amount', style: TextStyle(fontSize: 14, color: _budget == amount ? colorScheme.primary : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              _feeRow('Runner payment', '₦$_budget', colorScheme),
              const SizedBox(height: 12),
              _feeRow('Platform fee (15%)', '₦$_platformFee', colorScheme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: colorScheme.outlineVariant),
              ),
              _feeRow('Total to pay', '₦$_total', colorScheme, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep4(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Confirm', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        _reviewCard('Task', [
          _reviewRow('Title', _titleCtrl.text, colorScheme),
          _reviewRow('Category', AppConstants.categoryLabels[_category] ?? _category, colorScheme),
          _reviewRow('Urgency', _urgency, colorScheme),
        ], colorScheme),
        const SizedBox(height: 16),
        _reviewCard('Locations', [
          _reviewRow('Pickup', _pickupCtrl.text, colorScheme),
          _reviewRow('Destination', _destCtrl.text, colorScheme),
        ], colorScheme),
        const SizedBox(height: 16),
        _reviewCard('Payment', [
          _reviewRow('Budget', '₦$_budget', colorScheme),
          _reviewRow('Platform fee', '₦$_platformFee', colorScheme),
          _reviewRow('Total', '₦$_total', colorScheme),
        ], colorScheme),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.lock_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('₦ will be held securely in escrow and only released when you confirm the errand is complete.', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _CategoryPicker(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: AppConstants.categoryLabels.entries.map((e) => DropdownMenuItem(
        value: e.key,
        child: Text('${AppConstants.categoryEmojis[e.key] ?? "✨"} ${e.value}'),
      )).toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _urgencyChip(String value, String label, ColorScheme colorScheme) {
    final selected = _urgency == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
      selected: selected,
      selectedColor: colorScheme.primary.withOpacity(0.1),
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? colorScheme.primary : Colors.transparent),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onSelected: (_) => setState(() => _urgency = value),
    );
  }

  Widget _feeRow(String label, String value, ColorScheme colorScheme, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: bold ? colorScheme.onSurface : colorScheme.onSurfaceVariant, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 15, color: bold ? colorScheme.primary : colorScheme.onSurface, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }

  Widget _reviewCard(String title, List<Widget> rows, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.primary)),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface))),
        ],
      ),
    );
  }
}

