class SubscriptionPackageModel {
  int? id;
  String? iosProductId;
  String? name;
  double? price;
  String? formattedPrice; // Formatted price from API
  double? finalPrice;
  String? formattedFinalPrice; // Formatted final price from API
  double? discount;
  String? duration;
  String? limit;
  String? type;
  String? icon;
  String? description;
  List<String>? keyPoints;
  List<String>? categories;
  int? status;
  String? createdAt;
  String? updatedAt;
  bool? isActive;
  List<UserPurchasedPackages>? userPurchasedPackages;
  String? listingDuration;

  SubscriptionPackageModel({
    this.id,
    this.iosProductId,
    this.name,
    this.price,
    this.finalPrice,
    this.discount,
    this.duration,
    this.limit,
    this.type,
    this.icon,
    this.description,
    this.keyPoints,
    this.categories,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.userPurchasedPackages,
    this.listingDuration,
  });

  SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    iosProductId = json['ios_product_id'];
    name = json['translated_name'] ?? json['name'];
    price = json['price'] != null ? json['price'].toDouble() : null;
    formattedPrice = json['formatted_price'];
    discount = json['discount_in_percentage'] != null
        ? json['discount_in_percentage'].toDouble()
        : null;
    finalPrice = json['final_price'] != null
        ? json['final_price'].toDouble()
        : null;
    formattedFinalPrice = json['formatted_final_price'];
    duration = json['duration'];
    limit = json['item_limit'];
    type = json['type'];
    icon = json['icon'];
    description = json['translated_description'] ?? json['description'];

    keyPoints = ((json['translated_key_points'] ?? json['key_points']) as List)
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();

    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List)
          .where((e) => e != null && e is Map)
          .map((e) {
            final category = e as Map<String, dynamic>;
            return (category['translated_name'] ?? category['name'])
                    ?.toString() ??
                '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
    }
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isActive = json['is_active'];
    if (json['user_purchased_packages'] != null) {
      userPurchasedPackages = <UserPurchasedPackages>[];
      json['user_purchased_packages'].forEach((v) {
        userPurchasedPackages!.add(UserPurchasedPackages.fromJson(v));
      });
    }
    listingDuration = '${json['listing_duration_days']}';
  }

  @override
  String toString() {
    return 'SubscriptionPackageModel(id: $id, name: $name, duration: $duration, price: $price,final_price: $finalPrice,discount_in_percentage:$discount, status: $status, item_limit: $limit, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, icon: $icon,description: $description,keyPoints: $keyPoints,categories: $categories,is_active: $isActive)';
  }
}

class UserPurchasedPackages {
  int? id;
  int? userId;
  int? packageId;
  String? startDate;
  String? endDate;
  int? totalLimit;
  int? usedLimit;
  String? createdAt;
  String? updatedAt;
  String? remainingDays;
  String? remainingItemLimit;
  String? listingDurationDays;

  UserPurchasedPackages({
    this.id,
    this.userId,
    this.packageId,
    this.startDate,
    this.endDate,
    this.totalLimit,
    this.usedLimit,
    this.createdAt,
    this.updatedAt,
    this.remainingDays,
    this.remainingItemLimit,
    this.listingDurationDays
  });

  UserPurchasedPackages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    packageId = json['package_id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    totalLimit = json['total_limit'];
    usedLimit = json['used_limit'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    remainingDays = json['remaining_days'].toString();
    remainingItemLimit = json['remaining_item_limit'].toString();
    listingDurationDays = json['listing_duration_days'].toString();
  }
}
