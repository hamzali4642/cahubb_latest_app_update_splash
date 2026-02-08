class PaymentGateway {
  final String name;
  final String? key;
  final String? currency;
  final int status;
  final String type;
  final String? bankAccountHolderName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankIfscSwiftCode;

  PaymentGateway({
    required this.name,
    this.key,
    this.currency,
    required this.status,
    required this.type,
    this.bankAccountHolderName,
    this.bankAccountNumber,
    this.bankIfscSwiftCode,
    this.bankName,
  });
}

class PaymentSettings {
  static List<PaymentGateway> paymentGateways = [];

  static void updatePaymentGateways() {
    paymentGateways = [
      PaymentGateway(
        name: "Stripe",
        key: stripePublishableKey,
        currency: stripeCurrency,
        status: stripeStatus,
        type: "stripe",
      ),
      PaymentGateway(
        name: "Paystack",
        key: payStackKey,
        currency: payStackCurrency,
        status: payStackStatus,
        type: "paystack",
      ),
      PaymentGateway(
        name: "Razorpay",
        key: razorpayKey,
        currency: razorpayCurrency,
        status: razorpayStatus,
        type: "razorpay",
      ),
      PaymentGateway(
        name: "PhonePe",
        key: phonePeKey,
        currency: phonePeCurrency,
        status: phonePeStatus,
        type: "phonepe",
      ),
      PaymentGateway(
        name: "Flutterwave",
        key: flutterwaveKey,
        currency: flutterwaveCurrency,
        status: flutterwaveStatus,
        type: "flutterwave",
      ),
      PaymentGateway(name: "PayPal", status: paypalStatus, type: "PayPal"),
      PaymentGateway(
        name: "BankTransfer",
        status: bankTransferStatus,
        type: "bankTransfer",
        bankName: bankName,
        bankIfscSwiftCode: bankIfscSwiftCode,
        bankAccountHolderName: bankAccountHolderName,
        bankAccountNumber: bankAccountNumber,
      ),
    ];
  }

  static String enabledPaymentGateway = "";
  static String razorpayKey = "";
  static int razorpayStatus = 1;
  static String razorpayCurrency = "";
  static String payStackKey = "";
  static String payStackCurrency = "";
  static int payStackStatus = 1;
  static String paypalClientId = "";
  static String paypalServerKey = "";
  static bool isSandBoxMode = true;
  static String paypalCancelURL = "";
  static String paypalReturnURL = "";
  static String stripeCurrency = "";
  static String stripePublishableKey = "";
  static int stripeStatus = 1;
  static int phonePeStatus = 1;
  static String phonePeKey = "";
  static String phonePeCurrency = "";
  static int flutterwaveStatus = 1;
  static String flutterwaveKey = "";
  static String flutterwaveCurrency = "";
  static int bankTransferStatus = 1;
  static String bankAccountHolderName = "";
  static String bankAccountNumber = "";
  static String bankName = "";
  static String bankIfscSwiftCode = "";
  static int paypalStatus = 1;
  static String paypalCurrency = "";

  static List<PaymentGateway> getEnabledPaymentGateways() {
    return paymentGateways.where((gateway) => gateway.status == 1).toList();
  }
}
