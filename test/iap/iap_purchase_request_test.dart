import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/shop/domain/iap_catalog.dart';
import 'package:mythdusk/firebase/cloud_functions_client.dart';
import 'package:mythdusk/services/iap/iap_service.dart';

void main() {
  test('catalog product ids are store-stable', () {
    expect(IapCatalog.starterPack.id, 'mythdusk_starter_pack');
    expect(IapCatalog.starterPack.kind, IapProductKind.nonConsumable);
    expect(IapCatalog.gemsSmall.kind, IapProductKind.consumable);
  });

  test('unavailable port never grants', () async {
    const port = UnavailableIapPurchasePort();
    final result = await port.purchase(
      const IapPurchaseRequest(
        productId: 'mythdusk_starter_pack',
        receiptId: 'r1',
        platform: 'android',
        verificationData: 'token',
      ),
    );
    expect(result.success, isFalse);
  });

  test('callable port rejects unknown product before network', () async {
    final port =
        CallableIapPurchasePort((_) async => {'alreadyProcessed': false});
    final result = await port.purchase(
      const IapPurchaseRequest(
        productId: 'not_a_real_sku',
        receiptId: 'r1',
      ),
    );
    expect(result.success, isFalse);
    expect(result.message, 'Unknown product.');
  });

  test('ValidateIapResult parses Function payload', () {
    final result = ValidateIapResult.fromMap({
      'productId': 'mythdusk_starter_pack',
      'alreadyProcessed': true,
    });
    expect(result.productId, 'mythdusk_starter_pack');
    expect(result.alreadyProcessed, isTrue);
  });
}
