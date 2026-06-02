// ─────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────
class UserModel {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isPremium;
  final String plan;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.isPremium,
    required this.plan,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId:    json['userId'] as int,
    name:      json['name'] as String,
    email:     json['email'] as String,
    phone:     json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    isPremium: json['isPremium'] as bool? ?? false,
    plan:      json['plan'] as String? ?? 'free',
    isVerified: json['isVerified'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'isPremium': isPremium,
    'plan': plan,
    'isVerified': isVerified,
    'createdAt': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    bool? isPremium,
    String? plan,
    bool? isVerified,
  }) => UserModel(
    userId: userId,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    isPremium: isPremium ?? this.isPremium,
    plan: plan ?? this.plan,
    isVerified: isVerified ?? this.isVerified,
    createdAt: createdAt,
  );
}

// ─────────────────────────────────────────
// AUTH RESPONSE
// ─────────────────────────────────────────
class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] as String,
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}

// ─────────────────────────────────────────
// CATEGORY MODEL
// ─────────────────────────────────────────
class CategoryModel {
  final int categoryId;
  final String name;
  final String? icon;
  final String? color;

  const CategoryModel({
    required this.categoryId,
    required this.name,
    this.icon,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    categoryId: json['category_id'] as int,
    name:       json['name'] as String,
    icon:       json['icon'] as String?,
    color:      json['color'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'name': name,
    'icon': icon,
    'color': color,
  };
}

// ─────────────────────────────────────────
// TRANSACTION MODEL
// ─────────────────────────────────────────
class TransactionModel {
  final int transactionId;
  final int userId;
  final String merchantName;
  final double amount;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final DateTime date;
  final String? notes;
  final String source; // manual | ocr | ai
  final String? imageUrl;
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.merchantName,
    required this.amount,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.date,
    this.notes,
    required this.source,
    this.imageUrl,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    transactionId: json['transaction_id'] as int,
    userId:        json['user_id'] as int,
    merchantName:  json['merchant_name'] as String? ?? 'Unknown',
    amount:        double.tryParse(json['amount'].toString()) ?? 0,
    categoryId:    json['category_id'] as int?,
    categoryName:  json['category_name'] as String?,
    categoryColor: json['category_color'] as String?,
    date:          DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    notes:         json['notes'] as String?,
    source:        json['source'] as String? ?? 'manual',
    imageUrl:      json['image_url'] as String?,
    createdAt:     DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'merchant_name': merchantName,
    'amount': amount,
    'category_id': categoryId,
    'date': date.toIso8601String().split('T').first,
    'notes': notes,
    'source': source,
    'image_url': imageUrl,
  };

  TransactionModel copyWith({
    String? merchantName,
    double? amount,
    int? categoryId,
    String? categoryName,
    DateTime? date,
    String? notes,
    String? imageUrl,
  }) => TransactionModel(
    transactionId: transactionId,
    userId: userId,
    merchantName: merchantName ?? this.merchantName,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    categoryColor: categoryColor,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    source: source,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt,
  );
}

// ─────────────────────────────────────────
// DASHBOARD / SUMMARY
// ─────────────────────────────────────────
class CategorySummary {
  final String name;
  final double amount;
  final double percent;
  final String? color;

  const CategorySummary({
    required this.name,
    required this.amount,
    required this.percent,
    this.color,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) => CategorySummary(
    name:    json['category'] as String,
    amount:  double.tryParse(json['total'].toString()) ?? 0,
    percent: double.tryParse(json['percent']?.toString() ?? '0') ?? 0,
    color:   json['color'] as String?,
  );
}

class DashboardData {
  final double totalMonthly;
  final double totalWeekly;
  final List<CategorySummary> categoryBreakdown;
  final List<TransactionModel> recentTransactions;
  final BudgetStatus? budgetStatus;
  final AiInsight? latestInsight;

  const DashboardData({
    required this.totalMonthly,
    required this.totalWeekly,
    required this.categoryBreakdown,
    required this.recentTransactions,
    this.budgetStatus,
    this.latestInsight,
  });
}

// ─────────────────────────────────────────
// BUDGET MODEL
// ─────────────────────────────────────────
class BudgetModel {
  final int budgetId;
  final int userId;
  final int? categoryId;
  final String? categoryName;
  final double amount;
  final double spent;
  final String period;
  final int? month;
  final int? year;

  const BudgetModel({
    required this.budgetId,
    required this.userId,
    this.categoryId,
    this.categoryName,
    required this.amount,
    required this.spent,
    required this.period,
    this.month,
    this.year,
  });

  double get usagePercent => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0;
  double get remaining => (amount - spent).clamp(0, double.infinity);
  bool get isOverBudget => spent > amount;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    budgetId:     json['budget_id'] as int,
    userId:       json['user_id'] as int,
    categoryId:   json['category_id'] as int?,
    categoryName: json['category_name'] as String?,
    amount:       double.tryParse(json['amount'].toString()) ?? 0,
    spent:        double.tryParse(json['spent']?.toString() ?? '0') ?? 0,
    period:       json['period'] as String? ?? 'monthly',
    month:        json['month'] as int?,
    year:         json['year'] as int?,
  );
}

class BudgetStatus {
  final double totalBudget;
  final double totalSpent;
  final bool isOverBudget;
  final List<BudgetModel> budgets;

  const BudgetStatus({
    required this.totalBudget,
    required this.totalSpent,
    required this.isOverBudget,
    required this.budgets,
  });

  double get usagePercent =>
    totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0;
}

// ─────────────────────────────────────────
// OCR MODEL
// ─────────────────────────────────────────
class OcrResult {
  final String merchant;
  final double total;
  final String date;
  final List<OcrItem> items;
  final double confidence;
  final String rawText;
  final String? imageUrl;
  String? suggestedCategory;
  int? suggestedCategoryId;

  OcrResult({
    required this.merchant,
    required this.total,
    required this.date,
    required this.items,
    required this.confidence,
    required this.rawText,
    this.imageUrl,
    this.suggestedCategory,
    this.suggestedCategoryId,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return OcrResult(
      merchant:   data['merchant'] as String? ?? 'Tidak terdeteksi',
      total:      double.tryParse(data['total'].toString()) ?? 0,
      date:       data['date'] as String? ?? '',
      items:      (data['items'] as List<dynamic>?)
          ?.map((i) => OcrItem.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
      confidence: double.tryParse(data['confidence']?.toString() ?? '0') ?? 0,
      rawText:    data['rawText'] as String? ?? '',
      imageUrl:   data['image_url'] as String?,
      suggestedCategory:   data['suggestedCategory'] as String?,
      suggestedCategoryId: data['suggestedCategoryId'] as int?,
    );
  }
}

class OcrItem {
  final String name;
  final double price;
  final int? qty;

  const OcrItem({required this.name, required this.price, this.qty});

  factory OcrItem.fromJson(Map<String, dynamic> json) => OcrItem(
    name:  json['name'] as String,
    price: double.tryParse(json['price'].toString()) ?? 0,
    qty:   json['qty'] as int?,
  );
}

// ─────────────────────────────────────────
// AI INSIGHT MODEL
// ─────────────────────────────────────────
class AiInsight {
  final int insightId;
  final String type; // tip | warning | prediction | summary
  final String title;
  final String content;
  final bool isRead;
  final DateTime generatedAt;

  const AiInsight({
    required this.insightId,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.generatedAt,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) => AiInsight(
    insightId:   json['insight_id'] as int,
    type:        json['type'] as String,
    title:       json['title'] as String,
    content:     json['content'] as String,
    isRead:      json['is_read'] as bool? ?? false,
    generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
  );
}

// ─────────────────────────────────────────
// PAYMENT MODEL
// ─────────────────────────────────────────
class PaymentModel {
  final int paymentId;
  final String orderId;
  final double amount;
  final String status; // pending | success | failed | expired
  final String? snapToken;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.status,
    this.snapToken,
    this.paymentMethod,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    paymentId:     json['payment_id'] as int,
    orderId:       json['order_id'] as String,
    amount:        double.tryParse(json['amount'].toString()) ?? 0,
    status:        json['status'] as String,
    snapToken:     json['snap_token'] as String?,
    paymentMethod: json['payment_method'] as String?,
    paidAt:        json['paid_at'] != null
        ? DateTime.tryParse(json['paid_at'] as String)
        : null,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class SubscriptionStatus {
  final String plan; // free | premium
  final String status; // active | expired | cancelled
  final DateTime? expiresAt;
  final bool isActive;

  const SubscriptionStatus({
    required this.plan,
    required this.status,
    this.expiresAt,
    required this.isActive,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) => SubscriptionStatus(
    plan:      json['plan'] as String? ?? 'free',
    status:    json['status'] as String? ?? 'active',
    expiresAt: json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );
}

// ─────────────────────────────────────────
// NOTIFICATION MODEL
// ─────────────────────────────────────────
class NotificationModel {
  final int notifId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notifId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    notifId:   json['notif_id'] as int,
    type:      json['type'] as String,
    title:     json['title'] as String,
    message:   json['message'] as String,
    isRead:    json['is_read'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}
