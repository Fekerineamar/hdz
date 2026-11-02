import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/network/form_crypto.dart';
import '../../core/storage/secure_store.dart';
import '../../models/domain.dart';
import 'service_catalog_data.dart';

/// High-level operations against dzds.dz after a session is established:
/// browse services, start an application (scene instance), and manage
/// certificates / licenses.
class PortalClient {
  PortalClient(this._api);
  final ApiClient _api;

  String? _csrfToken;

  /// NextAuth CSRF token required by the CAP API POSTs (`X-Csrf-Token` header).
  ///
  /// The header must carry the full `token|hash` value stored in the
  /// `__Host-next-auth.csrf-token` cookie (URL-decoded); `/api/auth/csrf`
  /// only returns the `token` half, which is not enough.
  Future<String> _csrf() async {
    if (_csrfToken != null && _csrfToken!.isNotEmpty) return _csrfToken!;
    await _api.getJson(AppConfig.dzdsBase, Endpoints.authCsrf);
    final raw = await _api.cookie('__Host-next-auth.csrf-token') ??
        await _api.cookie('next-auth.csrf-token') ??
        '';
    _csrfToken = Uri.decodeComponent(raw);
    return _csrfToken!;
  }

  /// POSTs to the CAP API with the required NextAuth CSRF + language headers.
  ///
  /// The CAP service engine is privilege-protected: before the first real call
  /// (or after the license expires) it answers with `لا إذن` (WCAP000003 /
  /// WCAP000120) and asks the user to re-enter their password. When that
  /// happens we transparently run [validateUserLicense] (using the stored
  /// password) and retry the request once.
  Future<Map<String, dynamic>> _capPost(
      String path, Map<String, dynamic> data) async {
    var r = await _postCap(path, data);
    if (isPrivilegeError(r)) {
      final password = await SecureStore.instance.password ?? '';
      if (password.isNotEmpty) {
        print('[PORTAL] $path -> privilege required, re-validating license…');
        await validateUserLicense(password);
        r = await _postCap(path, data);
      }
    }
    print('[PORTAL] $path -> $r');
    return r;
  }

  Future<Map<String, dynamic>> _postCap(
      String path, Map<String, dynamic> data) async {
    final csrf = await _csrf();
    return _api.postJsonWithRetry(
      AppConfig.dzdsBase,
      path,
      data: data,
      options: DioOptions(
        contentType: 'application/json',
        headers: {
          'X-Csrf-Token': csrf,
          'Content-Language': 'ar-DZ',
          'Lang': 'ar_DZ',
          'Origin': 'https://dzds.dz',
        },
      ),
    );
  }

  /// True when a portal response reports a missing privilege/license instead
  /// of the requested data (the `لا إذن` family of errors).
  static bool isPrivilegeError(Map<String, dynamic> r) {
    if (r['flag'] == true) return false;
    final code = '${r['errorCode'] ?? ''}';
    final message = '${r['message'] ?? ''}';
    return code == 'WCAP000003' ||
        code == 'WCAP000120' ||
        message.contains('لا إذن') ||
        message.contains('إعادة إدخال كلمة المرور');
  }

  /// Re-validates the account "license" (privilege elevation). The portal
  /// requires the user to re-enter their password — AES-GCM encrypted with the
  /// fixed key recovered from the front-end — before the CAP service engine
  /// will answer. On success the server sets a flag that unlocks [listServices]
  /// downstream calls such as scene-instance-add and license-list.
  Future<Map<String, dynamic>> validateUserLicense(String password) async {
    return _postCap(Endpoints.userValidateLicense,
        {'password': FormCrypto.encryptUserPassword(password)});
  }

  /// Safely extracts the `data` map from a portal response (some error
  /// responses return `data` as a bool/null instead of an object).
  static Map<String, dynamic> dataAsMap(Map<String, dynamic> response) {
    final d = response['data'];
    return d is Map ? Map<String, dynamic>.from(d) : const {};
  }

  /// Current authenticated user.
  Future<UserSession?> session() async {
    final r = await _api.getJson(AppConfig.dzdsBase, Endpoints.authSession);
    if (r['user'] is Map) {
      return UserSession.fromJson(r);
    }
    return null;
  }

  /// Lists services from the full bundled catalog (63 services), optionally
  /// filtered by [query]. The query matches the Arabic name, English name or
  /// department name.
  Future<List<ServiceItem>> listServices({String query = ''}) async {
    final q = query.trim().toLowerCase();
    final items = <ServiceItem>[];
    serviceCatalogMeta.forEach((unid, e) {
      if (q.isNotEmpty &&
          !e.nameAr.toLowerCase().contains(q) &&
          !e.nameEn.toLowerCase().contains(q) &&
          !e.deptName.toLowerCase().contains(q)) {
        return;
      }
      items.add(ServiceItem(
        unid: unid,
        code: unid,
        name: e.nameAr,
        nameEn: e.nameEn,
        deptName: e.deptName,
        description: e.description,
      ));
    });
    return items;
  }

  /// Static catalog entry for [serviceUnid], or null if unknown.
  ServiceCatalogEntry? catalogEntry(String serviceUnid) =>
      serviceCatalogMeta[serviceUnid];

  /// Pre-application guide questions for [serviceUnid]. Empty for services that
  /// redirect to an external portal (no on-portal form).
  List<ServiceGuideQuestion> serviceGuide(String serviceUnid) =>
      serviceGuides[serviceUnid] ?? const [];

  /// Service-scene configuration for a given service.
  Future<Map<String, dynamic>> serviceSceneConfig(String serviceUnid) async {
    return _api.getJson(
      AppConfig.dzdsBase,
      Endpoints.serviceSceneConfig,
      query: {'serviceUnid': serviceUnid, 'handleChannel': 'WEBSITE'},
    );
  }

  /// Create an application instance; returns the `projid` and form URL.
  Future<Map<String, dynamic>> createSceneInstance(
    String serviceUnid, {
    String answerIds = '',
  }) async {
    return _capPost(
      Endpoints.sceneInstanceAdd,
      {
        'data': {
          'serviceUnid': serviceUnid,
          'answerIds': answerIds,
          'preSceneQASubmitDtoList': [],
          'deptId': 'OZ4gOOOOOOOOOOOOOOOO',
          'declarationTime': 1,
          'isIntranet': false,
        },
      },
    );
  }

  /// Basic application info (applicant, service, current state).
  Future<Map<String, dynamic>> apasinfoBasicGet(String projid) async {
    return _api.postJson(
      AppConfig.dzdsBase,
      Endpoints.apasinfoBasicGet,
      data: {'projid': projid},
    );
  }

  /// List certificates (electronic certificates).
  Future<List<Certificate>> certificateList() async {
    final r = await _capPost(Endpoints.licenseList,
        {'currentPageNum': 1, 'countPerPage': 20});
    final data = r['data'];
    if (data is List) {
      return data
          .map((e) => Certificate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  /// Certificate detail for the given license code.
  Future<Map<String, dynamic>> certificateDetail(String identifier) async {
    return _capPost(Endpoints.licenseDetail, {'licenseCode': identifier});
  }

  /// Download a certificate PDF, returns the raw bytes.
  Future<List<int>> downloadCertificate(String identifier) async {
    final res = await _api.dio.get(
      '${AppConfig.dzdsBase}${Endpoints.downloadLicenseFile}',
      queryParameters: {'licenseCode': identifier},
      options: DioOptions(
        responseType: ResponseType.bytes,
        headers: {
          'X-Csrf-Token': await _csrf(),
          'Content-Language': 'ar-DZ',
          'Lang': 'ar_DZ',
        },
      ),
    );
    final data = res.data;
    if (data is List<int>) return data;
    if (data is String) return data.codeUnits;
    return const [];
  }

  // ---------------------------------------------------------------------
  // Well-form engine (encrypted POSTs)
  // ---------------------------------------------------------------------

  /// POSTs to the well-form engine with the portal's AES/RSA request
  /// encryption (`encData` body + `Hoox-Data-Key` header).
  Future<Map<String, dynamic>> _formPost(
      String path, Map<String, dynamic> data) async {
    final enc = FormCrypto.encryptJson(data);
    final res = await _api.dio.post(
      '${AppConfig.dzdsBase}$path',
      data: {'encData': enc.encData},
      options: DioOptions(
        contentType: 'application/json',
        headers: {
          'Hoox-Data-Key': enc.hooxDataKey,
          'Content-Language': 'ar-DZ',
          'Origin': 'https://dzds.dz',
        },
      ),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Resolves the `form_id` + `affair_id` for a form relation (the `id` from
  /// the `yunFormUrl` returned by scene-instance-add).
  Future<Map<String, dynamic>> formAffairRela(String formRelationId) async {
    return _formPost(Endpoints.formGetAffairRela,
        {'affair_id': formRelationId});
  }

  /// Loads the form structure (form_meta + form_components) for a form.
  Future<Map<String, dynamic>> formData(String formId) async {
    return _formPost(Endpoints.formGetData, {'form_id': formId});
  }

  /// Submits the filled form values (well-form `saveByValue`).
  Future<Map<String, dynamic>> saveForm({
    required String serviceUnid,
    required String instanceId,
    required List<Map<String, dynamic>> valueDtoList,
  }) async {
    return _formPost(Endpoints.formSave, {
      'serviceUnid': serviceUnid,
      'instance_id': instanceId,
      'mode': 'sh',
      'extra_params': '',
      'fill_type': 0,
      'fill_used_time': 0,
      'fill_time': 0,
      'value_dto_list': valueDtoList,
    });
  }
}
