import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learn_chinese_by_music/services/api_service.dart';
import 'package:learn_chinese_by_music/features/payments/payment_models.dart';
import 'package:learn_chinese_by_music/features/payments/payment_providers.dart';
import 'package:learn_chinese_by_music/features/payments/paywall_screen.dart';

class FakePaymentApi extends ApiService {
  FakePaymentApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/payments/subscription') {
      return Response(
        requestOptions: ro,
        data: {
          'subscription': 'premium',
          'expires_at': '2099-12-31T23:59:59Z',
          'purchased_songs': [],
          'has_access': true,
        },
        statusCode: 200,
      );
    }
    throw Exception('Unexpected path: $path');
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/payments/verify' && data is Map) {
      final receipt = data['receipt'] as String? ?? '';
      if (receipt.startsWith('mock-receipt-')) {
        return Response(
          requestOptions: ro,
          data: {'status': 'ok', 'subscription': 'premium'},
          statusCode: 200,
        );
      }
      return Response(
        requestOptions: ro,
        data: {'detail': 'Invalid receipt'},
        statusCode: 400,
      );
    }
    throw Exception('Unexpected path: $path');
  }

  @override
  Future<Response> put(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> delete(String path) => throw UnimplementedError();
}

class FakeFreePaymentApi extends ApiService {
  FakeFreePaymentApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final ro = RequestOptions(path: path);
    if (path == '/api/payments/subscription') {
      return Response(
        requestOptions: ro,
        data: {
          'subscription': 'free',
          'expires_at': null,
          'purchased_songs': [],
          'has_access': false,
        },
        statusCode: 200,
      );
    }
    throw Exception('Unexpected path: $path');
  }

  @override
  Future<Response> post(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> put(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> delete(String path) =>
      throw UnimplementedError();
}

class FakeErrorApi extends ApiService {
  FakeErrorApi() : super();

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Network error',
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> put(String path, {dynamic data}) =>
      throw UnimplementedError();

  @override
  Future<Response> delete(String path) =>
      throw UnimplementedError();
}

void main() {
  group('SubscriptionInfo', () {
    test('fromJson parses premium subscription', () {
      final info = SubscriptionInfo.fromJson({
        'subscription': 'premium',
        'expires_at': '2099-12-31T23:59:59Z',
        'purchased_songs': ['song-1'],
        'has_access': true,
      });

      expect(info.subscription, 'premium');
      expect(info.isPremium, true);
      expect(info.purchasedSongs, ['song-1']);
    });

    test('fromJson parses free subscription', () {
      final info = SubscriptionInfo.fromJson({
        'subscription': 'free',
        'purchased_songs': [],
        'has_access': false,
      });

      expect(info.subscription, 'free');
      expect(info.isPremium, false);
      expect(info.purchasedSongs, isEmpty);
    });

    test('fromJson parses minimal json', () {
      final info = SubscriptionInfo.fromJson({});

      expect(info.subscription, 'free');
      expect(info.isPremium, false);
    });

    test('isPremium returns true only when premium and has access', () {
      expect(
        const SubscriptionInfo(
          subscription: 'premium',
          purchasedSongs: [],
          hasAccess: true,
        ).isPremium,
        true,
      );
      expect(
        const SubscriptionInfo(
          subscription: 'premium',
          purchasedSongs: [],
          hasAccess: false,
        ).isPremium,
        false,
      );
      expect(
        const SubscriptionInfo(
          subscription: 'free',
          purchasedSongs: [],
          hasAccess: false,
        ).isPremium,
        false,
      );
    });
  });

  group('PaymentProducts', () {
    test('has monthly and yearly products', () {
      expect(PaywallScreen.products.length, 2);
      expect(PaywallScreen.products[0].id, 'monthly_subscription');
      expect(PaywallScreen.products[1].id, 'yearly_subscription');
      expect(PaywallScreen.products[1].isPopular, true);
    });
  });

  group('subscriptionProvider', () {
    test('returns premium subscription info', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakePaymentApi()),
      ]);

      final info = await container.read(subscriptionProvider.future);

      expect(info.subscription, 'premium');
      expect(info.hasAccess, true);
      expect(info.isPremium, true);

      container.dispose();
    });

    test('returns free subscription info', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeFreePaymentApi()),
      ]);

      final info = await container.read(subscriptionProvider.future);

      expect(info.subscription, 'free');
      expect(info.hasAccess, false);
      expect(info.isPremium, false);

      container.dispose();
    });

    test('returns default free on error', () async {
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(FakeErrorApi()),
      ]);

      final info = await container.read(subscriptionProvider.future);

      expect(info.subscription, 'free');
      expect(info.hasAccess, false);

      container.dispose();
    });
  });
}
