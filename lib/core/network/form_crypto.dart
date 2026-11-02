import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asn1.dart' as pc_asn1;
import 'package:pointycastle/export.dart' as pc;

/// Replicates the portal form-engine's request encryption (extracted from the
/// minified `formCenter/js/app.*.js` bundle).
///
/// Every POST to `/formCenter/well/form/...` carries a body of the form
/// `{"encData": "<base64>"}` and a `Hoox-Data-Key` header. The scheme is:
///
///   1. Generate a random 48-char key = 16 hex chars (IV) + 32 chars (key).
///   2. RSA-encrypt (PKCS#1 v1.5) that 48-char key with the public key below,
///      base64 → sent in the `Hoox-Data-Key` header.
///   3. AES-256-CBC (PKCS7) encrypt `"data:" + JSON.stringify(payload)` using
///      iv = first 16 chars and key = last 32 chars, base64 → `encData`.
class FormCrypto {
  FormCrypto._();

  static const String rsaPublicKeyBase64 =
      'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArHfiF8QFib6H841bOJwq'
      'gl0XlPR8Fqw/HIWP9psXZfj6WgSfh3croufznmOZOKWlAs3hLlm+8Qy+niNnQ7JJ'
      'YMkCDWrYmdaQWIO71IDnNart65LHIo4JUrmuYQ9Bz2FQeBJuIz0sSJ9L39WO4quz'
      'XHEf9ZgKqNXG/hW+KgdVhu46BH6ERyCLbT22vz5qp5hOaoeWf4TLVQqn8gRVonTt'
      '7BV7NTyhc8B0uVofKzJtUVsjfIAuu017itPwhbh41h3A0rH0jkV95oN+Xfbh1tXw'
      '37KU61bb/STZRcUQU4/+P2Ucs4k4qdS42TBC0uk86qPl7rwdOy1x8swlqCD4ORfc'
      '0QIDAQAB';

  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_/-';

  static final Random _rng = Random.secure();

  /// Returns `(encData, hooxDataKey)` for the given [payload].
  static ({String encData, String hooxDataKey}) encryptJson(Object? payload) {
    final key = _randomKey();
    final iv = key.substring(0, 16);
    final aesKey = key.substring(16);

    final plain = 'data:${jsonEncode(payload ?? const {})}';
    final encrypter = enc.Encrypter(enc.AES(
      enc.Key.fromUtf8(aesKey),
      mode: enc.AESMode.cbc,
      padding: 'PKCS7',
    ));
    final encData =
        encrypter.encrypt(plain, iv: enc.IV.fromUtf8(iv)).base64;

    final hooxDataKey = _rsaEncrypt(key);
    return (encData: encData, hooxDataKey: hooxDataKey);
  }

  /// Fixed AES-256-GCM key used to encrypt the account password for the
  /// privilege-elevation step (`/api/user/validate-user-license`). Recovered
  /// from the portal's minified crypto chunk (the `iI` helper): the key is a
  /// 32-byte string obtained by Shamir secret-sharing + AES-GCM unwrapping.
  static const String _userPasswordKey = 'U0Xg55zo9-TglUjxvBG_Cbc_2NAsAyQc';

  /// Encrypts [password] exactly like the portal front-end does before calling
  /// `validate-user-license`: AES-256-GCM with the fixed key and a random
  /// 12-byte nonce, encoded as `base64(nonce || ciphertext || 16-byte tag)`.
  static String encryptUserPassword(String password) {
    final nonce =
        Uint8List.fromList(List.generate(12, (_) => _rng.nextInt(256)));
    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.AEADParameters(
          pc.KeyParameter(Uint8List.fromList(utf8.encode(_userPasswordKey))),
          128, // 16-byte GCM auth tag, matching the JS implementation.
          nonce,
          Uint8List(0), // no associated data
        ),
      );
    // `process` returns `ciphertext || tag` for GCM encryption.
    final ctTag = cipher.process(Uint8List.fromList(utf8.encode(password)));
    final out = Uint8List(nonce.length + ctTag.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, ctTag);
    return base64.encode(out);
  }

  /// Generates a random 48-char key: 16 hex chars + 32 chars from [_alphabet].
  static String _randomKey() {
    final hex = List.generate(8, (_) => _rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final tail = List.generate(
        32, (_) => _alphabet[_rng.nextInt(_alphabet.length)]).join();
    return hex + tail;
  }

  /// RSA PKCS#1 v1.5 encrypts [plain] with the portal's public key (base64 out).
  static String _rsaEncrypt(String plain) {
    final publicKey = _parseRsaPublicKey();

    final cipher = pc.PKCS1Encoding(pc.RSAEngine())
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    final encrypted = cipher.process(utf8.encode(plain));
    return base64.encode(encrypted);
  }

  /// Parses the hard-coded DER SubjectPublicKeyInfo into an [pc.RSAPublicKey].
  static pc.RSAPublicKey _parseRsaPublicKey() {
    final bytes = base64.decode(rsaPublicKeyBase64);
    // SubjectPublicKeyInfo ::= SEQUENCE { AlgorithmIdentifier, BIT STRING }
    final outer = pc_asn1.ASN1Parser(bytes).nextObject() as pc_asn1.ASN1Sequence;
    final bitString = outer.elements![1] as pc_asn1.ASN1BitString;
    // The BIT STRING content is a SEQUENCE { INTEGER modulus, INTEGER exponent }.
    final inner =
        pc_asn1.ASN1Parser(Uint8List.fromList(bitString.stringValues!))
            .nextObject() as pc_asn1.ASN1Sequence;
    final modulus = (inner.elements![0] as pc_asn1.ASN1Integer).integer!;
    final exponent = (inner.elements![1] as pc_asn1.ASN1Integer).integer!;
    return pc.RSAPublicKey(modulus, exponent);
  }
}
