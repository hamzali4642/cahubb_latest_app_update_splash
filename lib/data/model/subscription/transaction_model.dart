class TransactionModel {
  int? id;
  int? userId;
  double? amount;
  String? formattedAmount;
  String? paymentGateway;
  String? orderId;
  String? paymentId;
  String? paymentSignature;
  String? paymentStatus;
  String? createdAt;
  String? updatedAt;

  TransactionModel({
    this.id,
    this.userId,
    this.amount,
    this.formattedAmount,
    this.paymentGateway,
    this.orderId,
    this.paymentId,
    this.paymentSignature,
    this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    amount = (json['amount'] as num).toDouble();
    formattedAmount = json['formatted_amount'];
    paymentGateway = json['payment_gateway'];
    orderId = json['order_id'];
    paymentId = json['payment_id'];
    paymentSignature = json['payment_signature'];
    paymentStatus = json['payment_status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}
