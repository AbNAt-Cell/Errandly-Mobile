import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
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
        final errandId = response.data['errand']['id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrandDetailScreen(errandId: errandId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Errand'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.primary : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text('${i + 1}', style: TextStyle(color: i <= _step ? Colors.white : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                      ),
                      if (i < 3) Expanded(child: Container(height: 2, color: i < _step ? AppColors.primary : AppColors.border)),
                    ],
                  ),
                )),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStep(),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
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
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_step < 3 ? 'Continue' : 'Post Errand & Pay ₦$_total'),
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

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildStep1(),
      1 => _buildStep2(),
      2 => _buildStep3(),
      3 => _buildStep4(),
      _ => const SizedBox(),
    };
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What do you need done?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Task Title', hintText: 'e.g. Pick up my medicine'),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _CategoryPicker(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe exactly what you need done...', alignLabelWithHint: true),
          validator: (v) => ((v?.length ?? 0) < 10) ? 'Describe in more detail' : null,
        ),
        const SizedBox(height: 16),
        const Text('Urgency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _urgencyChip('standard', '🕐 Standard'),
            _urgencyChip('urgent', '⚡ Urgent'),
            _urgencyChip('scheduled', '📅 Scheduled'),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _itemDetailsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Item Details (optional)', hintText: 'List items, quantities, brands...')),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Where and to whom?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _pickupCtrl,
          decoration: const InputDecoration(labelText: 'Pickup Address', hintText: 'e.g. 12 Udo Udoma Ave, Uyo...', prefixIcon: Icon(Icons.radio_button_on, color: AppColors.primary)),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _destCtrl,
          decoration: const InputDecoration(labelText: 'Destination', hintText: '4 Adeola Odeku St, VI...', prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.danger)),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _recipientNameCtrl, decoration: const InputDecoration(labelText: 'Recipient Name (optional)', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 16),
        TextFormField(controller: _recipientPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Recipient Phone (optional)', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 16),
        TextFormField(controller: _specialCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Special Instructions (optional)')),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set your budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('The runner earns 100% of your budget. Platform fee is added on top.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              Text('₦$_budget', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Slider(
                value: _budget.toDouble(),
                min: 500, max: 50000,
                divisions: 99,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _budget = v.round()),
              ),
              Wrap(
                spacing: 8,
                children: [1000, 2000, 3500, 5000, 10000].map((amount) => GestureDetector(
                  onTap: () => setState(() => _budget = amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _budget == amount ? AppColors.primaryFaded : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _budget == amount ? AppColors.primary : AppColors.border),
                    ),
                    child: Text('₦$amount', style: TextStyle(fontSize: 12, color: _budget == amount ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              _feeRow('Runner payment', '₦$_budget'),
              const SizedBox(height: 8),
              _feeRow('Platform fee (15%)', '₦$_platformFee'),
              const Divider(height: 20),
              _feeRow('Total to pay', '₦$_total', bold: true),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review & Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        _reviewCard('Task', [
          _reviewRow('Title', _titleCtrl.text),
          _reviewRow('Category', AppConstants.categoryLabels[_category] ?? _category),
          _reviewRow('Urgency', _urgency),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Locations', [
          _reviewRow('Pickup', _pickupCtrl.text),
          _reviewRow('Destination', _destCtrl.text),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Payment', [
          _reviewRow('Budget', '₦$_budget'),
          _reviewRow('Platform fee', '₦$_platformFee'),
          _reviewRow('Total', '₦$_total'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.lock_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('₦ will be held securely in escrow and only released when you confirm the errand is complete.', style: TextStyle(color: AppColors.warning, fontSize: 13))),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _CategoryPicker() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(labelText: 'Category'),
      items: AppConstants.categoryLabels.entries.map((e) => DropdownMenuItem(
        value: e.key,
        child: Text('${AppConstants.categoryEmojis[e.key] ?? "✨"} ${e.value}'),
      )).toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _urgencyChip(String value, String label) {
    final selected = _urgency == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13, color: selected ? AppColors.primary : AppColors.textSecondary)),
      selected: selected,
      selectedColor: AppColors.primaryFaded,
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      onSelected: (_) => setState(() => _urgency = value),
    );
  }

  Widget _feeRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, color: bold ? AppColors.primary : AppColors.textPrimary, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
      ],
    );
  }

  Widget _reviewCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
