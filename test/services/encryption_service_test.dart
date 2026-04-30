import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bookend/services/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late EncryptionService service;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = EncryptionService(storage: mockStorage);
  });

  group('EncryptionService', () {
    test('getOrGenerateKey returns existing key if present', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'existing_key');

      final key = await service.getOrGenerateKey();

      expect(key, 'existing_key');
      verify(() => mockStorage.read(key: 'aes_encryption_key')).called(1);
      verifyNever(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('getOrGenerateKey generates and saves new key if none present', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});

      final key = await service.getOrGenerateKey();

      expect(key, isNotEmpty);
      expect(key.length, greaterThan(20)); // Base64 encoded 32 bytes
      verify(() => mockStorage.read(key: 'aes_encryption_key')).called(1);
      verify(() => mockStorage.write(key: 'aes_encryption_key', value: any(named: 'value'))).called(1);
    });
  });
}
