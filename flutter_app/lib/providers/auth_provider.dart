import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../core/network/dio_client.dart';
import '../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

// ─────────────────────────────────────────
// AUTH NOTIFIER
// ─────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._authService, this._storage)
      : super(const AuthState()) {
    _restoreSession();
  }

  // ── Restore session on app start ──────
  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final userJson = await _storage.read(key: AppConstants.userKey);

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>);
        state = AuthState(user: user, isInitialized: true);
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (_) {
      state = state.copyWith(isInitialized: true);
    }
  }

  // ── Email/Password Login ──────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authResponse = await _authService.login(
        email: email,
        password: password,
      );
      await _persistSession(authResponse);
      state = AuthState(user: authResponse.user, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // ── Register ─────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authResponse = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      await _persistSession(authResponse);
      state = AuthState(user: authResponse.user, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Google OAuth ──────────────────────
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google ID token null');

      final authResponse = await _authService.loginWithGoogle(idToken);
      await _persistSession(authResponse);
      state = AuthState(user: authResponse.user, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── WhatsApp OTP ──────────────────────
  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.sendOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authResponse =
          await _authService.verifyOtp(phone: phone, otp: otp);
      await _persistSession(authResponse);
      state = AuthState(user: authResponse.user, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Forgot / Reset Password ───────────
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Update local user (after profile edit) ──
  void updateUser(UserModel updatedUser) {
    state = state.copyWith(user: updatedUser);
    _storage.write(
        key: AppConstants.userKey, value: jsonEncode(updatedUser.toJson()));
  }

  // ── Logout ────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    await _storage.deleteAll();
    state = const AuthState(isInitialized: true);
  }

  // ── Persist session to secure storage ─
  Future<void> _persistSession(AuthResponse authResponse) async {
    await Future.wait([
      _storage.write(
          key: AppConstants.tokenKey, value: authResponse.token),
      _storage.write(
          key: AppConstants.userKey,
          value: jsonEncode(authResponse.user.toJson())),
    ]);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ─────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(secureStorageProvider),
  );
});
