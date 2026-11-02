import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/domain.dart';

/// Extracts structured fields from a photographed document (ID card, birth
/// certificate, marriage certificate, etc.) using Gemini vision.
///
/// Talks to the raw Gemini REST API (like [GeminiService]) because the official
/// SDK is incompatible with the Gemini 3.x protocol; we also try several flash
/// models in order because the free tier is quota-limited / overloaded.
class DocumentExtractor {
  DocumentExtractor(this._apiKey);

  final String _apiKey;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
  ));

  static const List<String> _models = [
    'gemini-3.6-flash',
    'gemini-3-flash-preview',
    'gemini-3.8-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
    'gemini-omni-flash-preview',
  ];

  static const Map<String, dynamic> _schema = {
    'type': 'OBJECT',
    'properties': {
      'document_type': {
        'type': 'STRING',
        'description': 'Short type, e.g. national_id_card or birth_certificate',
      },
      'fields': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'key': {'type': 'STRING', 'description': 'Field name in snake_case'},
            'value': {'type': 'STRING', 'description': 'Field value as text'},
          },
          'required': ['key', 'value'],
        },
      },
    },
    'required': ['document_type', 'fields'],
  };

  static const String _prompt =
      'These images show an Algerian identity document (such as Carte Nationale d\'Identité CNI front and back, Passport, or Birth Certificate). '
      'Extract every piece of personal data visible across ALL provided images, exactly as written. '
      'Return one entry per value using consistent snake_case keys. '
      'Crucial keys to extract: '
      'full_name_ar, first_name_ar, last_name_ar, '
      'full_name_fr, first_name_fr, last_name_fr, '
      'birth_date (use YYYY-MM-DD), birth_place, wilaya, commune, '
      'sex (male or female), nin (18-digit national identification number), '
      'cni (card number), cni_expire_date (expiration date YYYY-MM-DD, usually on the back), '
      'address (full residential address, usually on the back), father_name, mother_name. '
      'For dates use YYYY-MM-DD. Keep Arabic text as-is and Latin/French text as-is. '
      'Combine data from both sides into one complete object.';

  /// Runs extraction on one or more photographed images (e.g. front and back)
  /// and returns a [DocumentData] keyed by field name.
  Future<DocumentData> extract({
    Uint8List? imageBytes,
    List<Uint8List>? imagesBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final list = <Uint8List>[];
    if (imagesBytes != null) {
      list.addAll(imagesBytes.where((b) => b.isNotEmpty));
    }
    if (imageBytes != null && imageBytes.isNotEmpty && !list.contains(imageBytes)) {
      list.add(imageBytes);
    }
    if (list.isEmpty) return const DocumentData({});

    for (final model in _models) {
      try {
        final imageParts = <Map<String, dynamic>>[];
        for (final img in list) {
          imageParts.add({
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(img),
            },
          });
        }

        final body = <String, dynamic>{
          'contents': [
            {
              'role': 'user',
              'parts': [
                ...imageParts,
                {'text': _prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0,
            'responseMimeType': 'application/json',
            'responseSchema': _schema,
          },
        };

        final res = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$_apiKey',
          data: body,
          options: Options(contentType: Headers.jsonContentType),
        );

        final data = Map<String, dynamic>.from(res.data as Map);
        final candidates = (data['candidates'] as List?) ?? const [];
        if (candidates.isEmpty) {
          print('[DOC] $model: empty candidates');
          continue;
        }
        final content =
            Map<String, dynamic>.from((candidates.first as Map))['content'];
        final parts = (content is Map ? content['parts'] : null) as List? ??
            const [];
        var text = '';
        for (final raw in parts) {
          final part = Map<String, dynamic>.from(raw as Map);
          if (part['text'] is String) text += '${part['text']}';
        }
        text = text.trim();
        if (text.isEmpty) {
          print('[DOC] $model: empty text');
          continue;
        }

        try {
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final fields = <String, String>{};
          for (final entry in (decoded['fields'] as List? ?? const [])) {
            final m = Map<String, dynamic>.from(entry as Map);
            fields['${m['key']}'] = '${m['value']}';
          }
          if (decoded['document_type'] != null) {
            fields['document_type'] = '${decoded['document_type']}';
          }
          print('[DOC] $model extracted ${fields.length} fields: '
              '${fields.keys.join(',')}');
          return DocumentData(fields);
        } catch (e) {
          print('[DOC] $model: JSON parse failed: $e; raw=$text');
        }
      } on DioException catch (e) {
        print('[DOC] $model -> ${e.response?.statusCode}, trying next');
      }
    }
    return const DocumentData({});
  }
}
