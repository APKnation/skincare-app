enum OrderStatus { placed, confirmed, onTheWay, delivered, cancelled }

enum PaymentMethod { mpesa, tigopesa, airtelmoney, wowza, cashOnDelivery }

enum PaymentStatus { unpaid, verifying, paid, failed }

extension OrderStatusName on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => 'Placed',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.onTheWay => 'On the way',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}

extension PaymentMethodName on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.mpesa => 'M-Pesa (Vodacom)',
        PaymentMethod.tigopesa => 'Tigo Pesa',
        PaymentMethod.airtelmoney => 'Airtel Money',
        PaymentMethod.wowza => 'Wowza / Mixx by Yas',
        PaymentMethod.cashOnDelivery => 'Cash on delivery',
      };

  bool get isMobileMoney => this != PaymentMethod.cashOnDelivery;
}

extension PaymentStatusName on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.unpaid => 'Unpaid',
        PaymentStatus.verifying => 'Verifying payment…',
        PaymentStatus.paid => 'Paid',
        PaymentStatus.failed => 'Payment failed',
      };
}

class OrderLine {
  final String productId;
  final String name;
  final int unitPriceTZS;
  final int quantity;

  const OrderLine({
    required this.productId,
    required this.name,
    required this.unitPriceTZS,
    required this.quantity,
  });

  int get total => unitPriceTZS * quantity;
}

class OrderEvent {
  final OrderStatus status;
  final String note;
  final DateTime at;

  const OrderEvent({required this.status, required this.note, required this.at});
}

class Order {
  final String id;
  final String userId;
  final List<OrderLine> lines;
  final int subtotalTZS;
  final int deliveryFeeTZS;
  final int totalTZS;
  final String recipientName;
  final String recipientPhone;
  final String address;
  final String city;
  final String deliveryNotes;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? paymentRef;
  final OrderStatus status;
  final List<OrderEvent> timeline;

  const Order({
    required this.id,
    required this.userId,
    required this.lines,
    required this.subtotalTZS,
    required this.deliveryFeeTZS,
    required this.totalTZS,
    required this.recipientName,
    required this.recipientPhone,
    required this.address,
    required this.city,
    required this.deliveryNotes,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentRef,
    required this.status,
    required this.timeline,
  });

  Order copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentRef,
    List<OrderEvent>? timeline,
  }) {
    return Order(
      id: id,
      userId: userId,
      lines: lines,
      subtotalTZS: subtotalTZS,
      deliveryFeeTZS: deliveryFeeTZS,
      totalTZS: totalTZS,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      address: address,
      city: city,
      deliveryNotes: deliveryNotes,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentRef: paymentRef ?? this.paymentRef,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
    );
  }

  int get totalItems => lines.fold(0, (sum, l) => sum + l.quantity);
}
