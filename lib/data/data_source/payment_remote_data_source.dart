import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Required for PlatformException
import 'package:purchases_flutter/purchases_flutter.dart';


abstract class PaymentRemoteDataSource {
  Future<void> init();
  Future<bool> purchaseListingFee();
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  // RevenueCat Production SDK Keys
  static const _androidApiKey = 'goog_KzjarxBbqUCyAzKZHwrxnodPuIb';
  static const _appleApiKey = 'goog_KzjarxBbqUCyAzKZHwrxnodPuIb';
  
  static const _proEntitlementId = 'study_market_pro';
  
  bool _isConfigured = false;

  @override
  Future<void> init() async {
    if (_isConfigured) return;
    
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_androidApiKey);
      } else {
        configuration = PurchasesConfiguration(_appleApiKey);
      }
      
      await Purchases.configure(configuration);
      _isConfigured = true;
      debugPrint('RevenueCat: Configured successfully');
    } catch (e) {
      debugPrint('RevenueCat: Configuration Error: $e');
    }
  }

  @override
  Future<bool> purchaseListingFee() async {
    try {
      // Ensure initialized before proceeding
      if (!_isConfigured) {
        debugPrint('RevenueCat: Not configured, initializing now...');
        await init();
      }

      debugPrint('RevenueCat: Fetching offerings...');
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current == null || offerings.current!.availablePackages.isEmpty) {
        debugPrint('RevenueCat: No active offerings found in dashboard.');
        return false;
      }

      final package = offerings.current!.availablePackages.first;
      debugPrint('RevenueCat: Attempting purchase of package: ${package.identifier}');

      // Using the direct purchase method supported by version 10.x
      final purchaseResult = await Purchases.purchasePackage(package);
      
      // Check if the specific entitlement is now active
      final bool hasPro = purchaseResult.customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;
      debugPrint('RevenueCat: Purchase complete. Entitlement $_proEntitlementId active: $hasPro');
      
      return hasPro;

    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('RevenueCat: ERROR CODE: $errorCode');
      debugPrint('RevenueCat: ERROR MESSAGE: ${e.message}');
      debugPrint('RevenueCat: ERROR DETAILS: ${e.details}');

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('RevenueCat: User cancelled the purchase.');
      } else {
        debugPrint('RevenueCat: Technical Error: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('RevenueCat: Unexpected Error: $e');
      return false;
    }
  }
}
