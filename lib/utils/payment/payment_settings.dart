class PaymentGateway {
  final String name;
  final int status;
  final String type;

  PaymentGateway({
    required this.name,
    required this.status,
    required this.type,
  });
}

class PaymentSettings {
  static List<PaymentGateway> paymentGateways = [];

  static void updatePaymentGateways() {
    paymentGateways = [
      PaymentGateway(
        name: "BankTransfer",
        status: bankTransferStatus,
        type: "bankTransfer",
      ),
    ];
  }

  static String enabledPaymentGateway = "";
  static int bankTransferStatus = 1;
  static String bankAccountHolderName = "";
  static String bankAccountNumber = "";
  static String bankName = "";
  static String bankIfscSwiftCode = "";

  static List<PaymentGateway> getEnabledPaymentGateways() {
    return paymentGateways.where((gateway) => gateway.status == 1).toList();
  }
}
