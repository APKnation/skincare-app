import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../widgets/customer_support_icon.dart';
import '../../widgets/interactive_button.dart';
import '../../widgets/magnetic_button.dart';
import 'payment_sheet.dart';

class CheckoutPage extends StatefulWidget {
  final Store store;

  const CheckoutPage({super.key, required this.store});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.currentUser?.name);
  late final _phone =
      TextEditingController(text: widget.store.currentUser?.phone);
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  PaymentMethod _method = PaymentMethod.mpesa;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _city, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await widget.store.placeOrder(
      recipientName: _name.text,
      recipientPhone: _phone.text,
      address: _address.text,
      city: _city.text,
      deliveryNotes: _notes.text,
      paymentMethod: _method,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final order = widget.store.myOrders.first;
    if (_method == PaymentMethod.cashOnDelivery) {
      _done(order);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => PaymentSheet(
          store: widget.store,
          order: order,
          onFinished: (paid) {
            if (context.mounted) Navigator.of(context).pop();
            _done(order, paid: paid);
          },
        ),
      );
    }
  }

  void _done(Order order, {bool? paid}) {
    Navigator.of(context).pop();
    final message = order.paymentMethod == PaymentMethod.cashOnDelivery
        ? 'Order ${order.id} placed — pay ${formatTZS(order.totalTZS)} on delivery.'
        : paid == true
            ? 'Order ${order.id} confirmed and paid.'
            : 'Order ${order.id} placed — payment incomplete. Pay from Orders.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.store.cartSubtotal;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Delivery details',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Recipient name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Enter a valid phone number'
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _address,
                decoration:
                    const InputDecoration(labelText: 'Address / landmark'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _city,
                decoration: const InputDecoration(
                    labelText: 'City (Dar es Salaam = lower fee)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _notes,
                decoration:
                    const InputDecoration(labelText: 'Delivery notes'),
            ),
            const SizedBox(height: 24),
            Text('Payment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Pay with'),
              items: [
                for (final m in PaymentMethod.values)
                  DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product summary',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final item in widget.store.cart)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(item.productId,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            Text('x${item.quantity}'),
                          ],
                        ),
                      ),
                    const Divider(),
                    _row(context, 'Subtotal', formatTZS(subtotal)),
                    _row(context, 'Delivery',
                        formatTZS(widget.store.deliveryFeeFor(_city.text))),
                    const Divider(),
                    _row(
                        context,
                        'Total',
                        formatTZS(subtotal +
                            widget.store.deliveryFeeFor(_city.text))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shipping & delivery information',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                        'Delivery fee: ${formatTZS(widget.store.deliveryFeeFor(_city.text))}. Lower fee for Dar es Salaam.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'For your safety, mobile money is verified server-side before an '
              'order is confirmed. Sura Yangu never asks you to share your PIN '
              'with anyone — you enter it only on your own handset prompt.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: const CustomerSupportIcon(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MagneticButton(
            onPressed: _busy ? null : _placeOrder,
            child: InteractiveButton(
              onPressed: _busy ? null : _placeOrder,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: Text(
                      _busy ? 'Placing order…' : 'Place order — ${formatTZS(subtotal + widget.store.deliveryFeeFor(_city.text))}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(a), Text(b)],
        ),
      );
}
