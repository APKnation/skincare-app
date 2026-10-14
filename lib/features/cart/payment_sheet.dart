import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';

class PaymentSheet extends StatefulWidget {
  final Store store;
  final Order order;
  final ValueChanged<bool> onFinished;

  const PaymentSheet({
    super.key,
    required this.store,
    required this.order,
    required this.onFinished,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  Map<String, Object?>? _prompt;
  final _pin = TextEditingController();
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final prompt = await widget.store.payStart(widget.order.id);
    if (!mounted) return;
    setState(() {
      _prompt = prompt;
      _busy = false;
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final outcome =
        await widget.store.payConfirm(widget.order.id, _pin.text);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(outcome.message)));
    widget.onFinished(outcome.success);
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _prompt;
    if (prompt == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : Text(
                'Could not start the payment request. Is the backend running?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay ${formatTZS(prompt['amountTZS'] as int)}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'A ${prompt['method']} request was sent to ${prompt['phone']} '
            '(ref ${prompt['reference']}).\n\n'
            'Prototype note: enter your handset PIN here as if approving the '
            'USSD push. Use 0000 to simulate declining the request.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Mobile money PIN'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.verified_outlined),
            label: Text(_busy
                ? 'Verifying with provider…'
                : 'Approve payment'),
            onPressed: _busy ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
