import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/transaction_service.dart';
import '../services/services.dart';

// ════════════════════════════════════════
// CATEGORY PROVIDER
// ════════════════════════════════════════
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.read(userServiceProvider).getCategories();
});

// ════════════════════════════════════════
// DASHBOARD PROVIDER
// ════════════════════════════════════════
class DashboardState {
  final double totalMonthly;
  final double totalWeekly;
  final List<CategorySummary> categoryBreakdown;
  final List<TransactionModel> recentTransactions;
  final BudgetStatus? budgetStatus;
  final AiInsight? latestInsight;
  final bool isLoading;
  final String? error;
  final String monthLabel;
  final bool hasUnreadNotif;
  final String userName;

  const DashboardState({
    this.totalMonthly = 0,
    this.totalWeekly = 0,
    this.categoryBreakdown = const [],
    this.recentTransactions = const [],
    this.budgetStatus,
    this.latestInsight,
    this.isLoading = true,
    this.error,
    this.monthLabel = '',
    this.hasUnreadNotif = false,
    this.userName = '',
  });

  double get budgetPercent => budgetStatus?.usagePercent ?? 0;
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async => _fetch();

  Future<DashboardState> _fetch() async {
    final txService = ref.read(transactionServiceProvider);
    final aiService = ref.read(aiServiceProvider);

    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      txService.getSummary(
          month: now.month.toString(), year: now.year.toString()),
      txService.getTransactions(limit: 5),
      aiService.getInsights(),
    ]);

    final summary = results[0] as Map<String, dynamic>;
    final recent = results[1] as List<TransactionModel>;
    final insights = results[2] as List<AiInsight>;

    final catList = (summary['categories'] as List<dynamic>? ?? [])
        .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardState(
      totalMonthly:
          double.tryParse(summary['totalMonthly']?.toString() ?? '0') ?? 0,
      totalWeekly:
          double.tryParse(summary['totalWeekly']?.toString() ?? '0') ?? 0,
      categoryBreakdown: catList,
      recentTransactions: recent,
      latestInsight: insights.isNotEmpty ? insights.first : null,
      isLoading: false,
      monthLabel: monthStr,
      userName: '',
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
        DashboardNotifier.new);

// ════════════════════════════════════════
// TRANSACTION LIST PROVIDER
// ════════════════════════════════════════
class TransactionFilter {
  final int? categoryId;
  final String? startDate;
  final String? endDate;
  final String? search;
  final int page;

  const TransactionFilter({
    this.categoryId,
    this.startDate,
    this.endDate,
    this.search,
    this.page = 1,
  });

  TransactionFilter copyWith({
    int? categoryId,
    String? startDate,
    String? endDate,
    String? search,
    int? page,
    bool clearCategory = false,
  }) =>
      TransactionFilter(
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        search: search ?? this.search,
        page: page ?? this.page,
      );
}

class TransactionListState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final TransactionFilter filter;

  const TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filter = const TransactionFilter(),
  });

  TransactionListState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    TransactionFilter? filter,
    bool clearError = false,
  }) =>
      TransactionListState(
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        filter: filter ?? this.filter,
      );
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionService _service;
  TransactionListNotifier(this._service) : super(const TransactionListState()) {
    fetch();
  }

  Future<void> fetch({bool reset = true}) async {
    if (reset) {
      state = state.copyWith(
          isLoading: true,
          transactions: [],
          filter: state.filter.copyWith(page: 1));
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final f = state.filter;
      final data = await _service.getTransactions(
        page: reset ? 1 : f.page,
        categoryId: f.categoryId,
        startDate: f.startDate,
        endDate: f.endDate,
        search: f.search,
      );

      final merged = reset ? data : [...state.transactions, ...data];
      state = state.copyWith(
        transactions: merged,
        isLoading: false,
        isLoadingMore: false,
        hasMore: data.length >= 20,
        filter:
            state.filter.copyWith(page: (reset ? 1 : state.filter.page) + 1),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, isLoadingMore: false, error: e.toString());
    }
  }

  void applyFilter(TransactionFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    fetch();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    await fetch(reset: false);
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      final tx = await _service.createTransaction(data);
      state = state.copyWith(transactions: [tx, ...state.transactions]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateTransaction(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateTransaction(id, data);
      state = state.copyWith(
        transactions: state.transactions
            .map((t) => t.transactionId == id ? updated : t)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _service.deleteTransaction(id);
      state = state.copyWith(
        transactions:
            state.transactions.where((t) => t.transactionId != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier(ref.read(transactionServiceProvider));
});

// ════════════════════════════════════════
// OCR PROVIDER
// ════════════════════════════════════════
class OcrState {
  final OcrResult? result;
  final bool isScanning;
  final String? error;

  const OcrState({this.result, this.isScanning = false, this.error});

  OcrState copyWith({
    OcrResult? result,
    bool? isScanning,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      OcrState(
        result: clearResult ? null : (result ?? this.result),
        isScanning: isScanning ?? this.isScanning,
        error: clearError ? null : (error ?? this.error),
      );
}

class OcrNotifier extends StateNotifier<OcrState> {
  final OcrService _service;
  OcrNotifier(this._service) : super(const OcrState());

  Future<bool> scanReceipt(dynamic imageFile) async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final result = await _service.scanReceipt(imageFile);
      state = state.copyWith(result: result, isScanning: false);
      return true;
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
      return false;
    }
  }

  void clearResult() {
    state = const OcrState();
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(ref.read(ocrServiceProvider));
});

// ════════════════════════════════════════
// AI INSIGHTS PROVIDER
// ════════════════════════════════════════
final aiInsightsProvider =
    FutureProvider.autoDispose<List<AiInsight>>((ref) async {
  return ref.watch(aiServiceProvider).getInsights();
});

// ════════════════════════════════════════
// PAYMENT PROVIDER
// ════════════════════════════════════════
class PaymentState {
  final SubscriptionStatus? subscription;
  final List<PaymentModel> history;
  final bool isLoading;
  final String? snapToken;
  final String? orderId;
  final String? error;

  const PaymentState({
    this.subscription,
    this.history = const [],
    this.isLoading = false,
    this.snapToken,
    this.orderId,
    this.error,
  });

  PaymentState copyWith({
    SubscriptionStatus? subscription,
    List<PaymentModel>? history,
    bool? isLoading,
    String? snapToken,
    String? orderId,
    String? error,
    bool clearSnap = false,
    bool clearError = false,
  }) =>
      PaymentState(
        subscription: subscription ?? this.subscription,
        history: history ?? this.history,
        isLoading: isLoading ?? this.isLoading,
        snapToken: clearSnap ? null : (snapToken ?? this.snapToken),
        orderId: clearSnap ? null : (orderId ?? this.orderId),
        error: clearError ? null : (error ?? this.error),
      );
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _service;
  PaymentNotifier(this._service) : super(const PaymentState()) {
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    try {
      final sub = await _service.getSubscriptionStatus();
      state = state.copyWith(subscription: sub);
    } catch (_) {}
  }

  Future<bool> createPayment() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _service.createPayment();
      state = state.copyWith(
        isLoading: false,
        snapToken: data['snapToken'] as String,
        orderId: data['orderId'] as String,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadHistory() async {
    try {
      final history = await _service.getPaymentHistory();
      state = state.copyWith(history: history);
    } catch (_) {}
  }

  void clearSnapToken() {
    state = state.copyWith(clearSnap: true);
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentServiceProvider));
});
