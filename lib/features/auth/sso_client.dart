import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../models/domain.dart';

/// Result of an auth step that needs no special UI.
class SsoResult {
  final bool ok;
  final String message;
  final Map<String, dynamic> data;

  const SsoResult(this.ok, this.message, [this.data = const {}]);
}

/// Implements the real SSO login flow captured from dzds.dz:
///
///   signin/cms → oauth authorize → authenticate (→ lck context)
///   → queryAuthMethods → captcha (puzzle) → sendSms → authExecute
///   → authnEngine → callback → session.
///
/// The instance keeps the OAuth `lck`, `authChainCode`, captcha `token` and
/// `agreementId` between steps, just like the browser flow does.
class SsoClient {
  SsoClient(this._api);
  final ApiClient _api;

  String? _lck;
  String? _authChainCode;
  String? _agreementId;
  String? _captchaToken;
  String? _loginToken;
  String? _requestNumber;
  String? _registerMobileToken;
  String? _registerToken;

  /// 1. Get a CSRF token (required by NextAuth signin).
  Future<String> getCsrfToken() async {
    final r = await _api.getJson(AppConfig.dzdsBase, Endpoints.authCsrf);
    return '${r['csrfToken'] ?? ''}';
  }

  /// 2. Kick off login, returns the SSO authorize URL.
  Future<String> startLogin(String csrfToken) async {
    final r = await _api.postForm(
      AppConfig.dzdsBase,
      Endpoints.authSigninCms,
      data: {
        'callbackUrl': 'https://dzds.dz/',
        'csrfToken': csrfToken,
        'json': 'true',
      },
    );
    return '${r['url'] ?? ''}';
  }

  /// 3-5. Follow the redirects to obtain the OAuth `lck` context. The lck can
  /// appear in any redirect's Location (query or `#` fragment), so we check
  /// each hop instead of assuming a fixed number of redirects.
  Future<String> establishContext(String authorizeUrl) async {
    var loc = authorizeUrl;
    for (var i = 0; i < 4; i++) {
      final res = await _api.dio.get(
        loc,
        options: DioOptions(followRedirects: false),
      );
      final next = _api.redirectLocation(res);
      if (next == null || next.isEmpty) break;
      loc = _ensureAbsolute(next);
      print('[SSO] redirect$i -> $loc');
      final lck = _queryParam(loc, 'lck');
      if (lck != null) {
        _lck = lck;
        print('[SSO] lck extracted: $lck');
        return loc;
      }
    }
    final lck = _queryParam(loc, 'lck');
    if (lck != null) _lck = lck;
    print('[SSO] lck extracted: $_lck');
    return loc;
  }

  /// Optional device signature call.
  Future<SsoResult> getSignature() async {
    final r = await _api.postJsonWithRetry(AppConfig.ssoBase, Endpoints.idpGetSignature,
        data: <String, dynamic>{});
    return SsoResult(true, '${r['message'] ?? 'ok'}', r);
  }

  /// 6. Discover available auth methods; caches the password-chain code.
  Future<SsoResult> queryAuthMethods() async {
    final r = await _api.postJsonWithRetry(
      AppConfig.ssoBase,
      Endpoints.idpQueryAuthMethods,
      data: {'lck': _lck, 'entityId': AppConfig.clientId},
    );
    final list = (r['data'] as List?) ?? const [];
    if (list.isNotEmpty) {
      final first = Map<String, dynamic>.from(list.first as Map);
      _authChainCode = '${first['authChainCode'] ?? ''}';
    }
    print('[SSO] queryAuthMethods response: $r');
    print('[SSO] queryAuthMethods authChainCode=$_authChainCode');
    return SsoResult(true, '${r['message'] ?? 'ok'}', r);
  }

  /// 7. Load the slider captcha puzzle.
  Future<CaptchaPuzzle> getCaptchaPuzzle() async {
    await _api.getJson(AppConfig.ssoBase, Endpoints.idpCaptchaCheckOpen);
    final r = await _api.getJson(AppConfig.ssoBase, Endpoints.idpCaptchaGetPuzzle);
    final p = CaptchaPuzzle.fromJson(r);
    _captchaToken = p.token;
    print('[SSO] getCaptchaPuzzle token=${p.token} '
        'bgBytes=${p.originalImageBase64.length} '
        'pieceBytes=${p.jigsawImageBase64.length}');
    return p;
  }

  /// 8. Validate the slider answer.
  Future<bool> checkCaptcha(double x, double y) async {
    final pointJson = jsonEncode({'x': x, 'y': y.toInt()});
    print('[SSO] checkCaptcha pointJson=$pointJson token=$_captchaToken');
    final r = await _api.postJsonWithRetry(
      AppConfig.ssoBase,
      Endpoints.idpCheckCaptcha,
      data: {'pointJson': pointJson, 'token': _captchaToken},
      options: DioOptions(
        contentType: 'application/json;charset=UTF-8',
        headers: {'Origin': 'https://sso.dzds.dz'},
      ),
    );
    print('[SSO] checkCaptcha raw response: $r');
    final data = r['data'];
    final result = data is Map ? data['result'] : null;
    print('[SSO] checkCaptcha result=$result');
    return result == true;
  }

  /// 9. Send the SMS verification code to the account phone.
  Future<SsoResult> sendSms(String loginName, double x, double y) async {
    final pointJson = jsonEncode({'x': x, 'y': y.toInt()});
    print('[SSO] sendSms loginName=$loginName pointJson=$pointJson '
        'token=$_captchaToken lck=$_lck');
    final r = await _api.postJsonWithRetry(
      AppConfig.ssoBase,
      Endpoints.idpSendSms,
      data: {
        'loginName': loginName,
        'pointJson': pointJson,
        'token': _captchaToken,
        'lck': _lck,
        'userType': 'personal',
      },
      options: DioOptions(
        contentType: 'application/json;charset=UTF-8',
        headers: {'Origin': 'https://sso.dzds.dz'},
      ),
    );
    print('[SSO] sendSms raw response: $r');
    return SsoResult('${r['code']}' == '200', '${r['message'] ?? ''}', r);
  }

  /// Fetch the "terms of use" agreement id required by authExecute.
  Future<String?> resolveAgreementId() async {
    final r = await _api.getJson(AppConfig.ssoBase, Endpoints.idpAgreementConfig);
    final list = (r['data'] as List?) ?? const [];
    for (final item in list) {
      final m = Map<String, dynamic>.from(item as Map);
      final subs = (m['list'] as List?) ?? const [];
      if (subs.isNotEmpty) {
        final s0 = Map<String, dynamic>.from(subs.first as Map);
        _agreementId = '${s0['id'] ?? ''}';
        print('[SSO] resolveAgreementId agreementId=$_agreementId');
        return _agreementId;
      }
    }
    print('[SSO] resolveAgreementId response: $r');
    return null;
  }

  /// 10. Authenticate with username+password (the first authExecute call).
  /// The response carries a `requestNumber` that the SMS step must echo back.
  Future<SsoResult> authExecutePassword({
    required String loginName,
    required String password,
  }) async {
    final r = await _api.postJsonWithRetry(
      AppConfig.ssoBase,
      Endpoints.idpAuthExecute,
      data: {
        'authModuleCode': 'userAndPwd',
        'authChainCode': _authChainCode ?? '',
        'entityId': AppConfig.clientId,
        'requestType': 'chain_type',
        'lck': _lck,
        'authPara': {
          'loginName': loginName,
          'password': password,
          'verifyCode': '',
        },
        'authChainType': 'personal',
        'agreementId': _agreementId ?? '',
        'E_Model': 'n',
      },
    );
    if (r['requestNumber'] != null && '${r['requestNumber']}'.isNotEmpty) {
      _requestNumber = '${r['requestNumber']}';
    }
    print('[SSO] authExecutePassword response: $r');
    return SsoResult('${r['code']}' == '200', '${r['message'] ?? ''}', r);
  }

  /// 10b. Submit the SMS code (the second authExecute call). This uses the
  /// `userAndSms` module and echoes the `requestNumber` from the password step;
  /// a successful reply returns the `loginToken`.
  Future<SsoResult> authExecuteSms({
    required String loginName,
    required String smsCode,
  }) async {
    final r = await _api.postJsonWithRetry(
      AppConfig.ssoBase,
      Endpoints.idpAuthExecute,
      data: {
        'authModuleCode': 'userAndSms',
        'authChainCode': _authChainCode ?? '',
        'entityId': AppConfig.clientId,
        'requestNumber': _requestNumber ?? '',
        'requestType': 'chain_type',
        'lck': _lck,
        'authPara': {
          'loginName': loginName,
          'smsCode': smsCode,
        },
        'E_Model': 'n',
      },
    );
    if (r['loginToken'] != null && '${r['loginToken']}'.isNotEmpty) {
      _loginToken = '${r['loginToken']}';
    }
    print('[SSO] authExecuteSms response: $r');
    return SsoResult('${r['code']}' == '200', '${r['message'] ?? ''}', r);
  }

  bool get hasLoginToken => _loginToken != null && _loginToken!.isNotEmpty;

  /// Non-null after a successful password auth; the SMS step echoes it back.
  String? get requestNumber =>
      _requestNumber != null && _requestNumber!.isNotEmpty ? _requestNumber : null;

  /// 11. Finalize auth and return the callback URL (containing `code`).
  Future<String> authnEngine() async {
    final res = await _api.dio.post(
      '${AppConfig.ssoBase}${Endpoints.idpAuthnEngine}?locale=ar_DZ&E_Model=n',
      data: {'loginToken': _loginToken},
      options: DioOptions(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
      ),
    );
    final html = '${res.data}';
    final match = RegExp(r'https://dzds\.dz/api/auth/callback/cms[^"]*')
        .firstMatch(html);
    final raw = match?.group(0) ?? '';
    // The HTML escapes & as &amp;; unescape before following the redirect.
    final unescaped = raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    print('[SSO] authnEngine callback=$unescaped');
    return unescaped;
  }

  /// 12. Complete the OAuth callback to establish the portal session.
  Future<SsoResult> completeCallback(String callbackUrl) async {
    await _api.dio.get(callbackUrl, options: DioOptions(followRedirects: false));
    return const SsoResult(true, 'session established');
  }

  /// True when a session already exists.
  Future<bool> hasSession() async {
    final r = await _api.getJson(AppConfig.dzdsBase, Endpoints.authSession);
    return r['user'] is Map;
  }

  // ---------------------------------------------------------------------
  // New-account registration (userRegister)
  // ---------------------------------------------------------------------

  /// Account fields (username/password/mobile/mail) + the id-card-type list.
  Future<Map<String, dynamic>> registerNaturalPersonAttributes() async {
    final r = await _api
        .getJson(AppConfig.ssoBase, Endpoints.idpRegisterNaturalPerson);
    print('[SSO] registerNaturalPersonAttributes keys=${r.keys}');
    return r;
  }

  /// Identity/document fields for a document type (0 = Algerian citizens).
  Future<Map<String, dynamic>> registerDocumentAttributes(String type) async {
    final r = await _api.getJson(
      AppConfig.ssoBase,
      Endpoints.idpRegisterDocumentAttributes,
      query: {'documentTypeCode': type},
    );
    return r;
  }

  /// Dictionary data for a `dictCode` (gender / presumed / province …).
  Future<List<Map<String, dynamic>>> registerDict(String dictCode) async {
    final r = await _api.getJson(
      AppConfig.ssoBase,
      Endpoints.idpRegisterDict,
      query: {'dictCode': dictCode},
    );
    final list = (r['data'] as List?) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Communes of a selected wilaya.
  Future<List<Map<String, dynamic>>> registerCities(String provinceId) async {
    final r = await _api.getJson(
      AppConfig.ssoBase,
      Endpoints.idpRegisterCities,
      query: {'parentId': provinceId},
    );
    final list = (r['data'] as List?) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Registration slider captcha (notification/getCaptcha). Reuses the shared
  /// [_captchaToken] so [checkCaptcha] validates against it.
  Future<CaptchaPuzzle> registerCaptcha() async {
    final r = await _api.getJson(AppConfig.ssoBase, Endpoints.idpNotifyGetCaptcha);
    final p = CaptchaPuzzle.fromJson(r);
    _captchaToken = p.token;
    print('[SSO] registerCaptcha token=${p.token}');
    return p;
  }

  /// Builds the `captchaVerifycation` value the registration endpoints expect:
  /// `<captcha token>---<pointJson>`.
  String captchaVerifycation(double x, double y) {
    final pointJson = jsonEncode({'x': x, 'y': y.toInt()});
    return '$_captchaToken---$pointJson';
  }

  /// Send the mobile verification code during registration. The server returns
  /// a `token` that saveUser must echo back inside the `mobile` object.
  Future<SsoResult> registerSendSecurityCode(
      String receiver, double x, double y) async {
    final captchaVerifycation = this.captchaVerifycation(x, y);
    print('[SSO] registerSendSecurityCode receiver=$receiver');
    final r = await _api.postJsonWithRetry(
      AppConfig.ssoBase,
      Endpoints.idpNotifySendSecurityCode,
      data: {
        'captchaVerifycation': captchaVerifycation,
        'receiver': receiver,
        'authType': 'SMS',
      },
      options: DioOptions(
        contentType: 'application/json;charset=UTF-8',
        headers: {'Origin': 'https://sso.dzds.dz'},
      ),
    );
    final data = r['data'];
    if (data is Map && data['token'] != null) {
      _registerMobileToken = '${data['token']}';
    }
    print('[SSO] registerSendSecurityCode response: $r');
    return SsoResult('${r['code']}' == '200', '${r['message'] ?? ''}', r);
  }

  /// Number of concurrent `saveUserSubmit` attempts. The registration backend
  /// sits behind a gateway that frequently times out (504), so a few identical
  /// requests fired at once raise the chance one gets through. The username is
  /// unique server-side, so at most one account is actually created.
  static const int _saveUserAttempts = 3;

  /// Step 1 — verify identity (with a slider captcha). On success the server
  /// returns a registration token that [registerSaveUserSubmit] must echo back.
  Future<SsoResult> registerSaveUserFirst(
    Map<String, dynamic> identityAttr,
    String captchaVerifycation,
  ) async {
    final Map<String, dynamic> r;
    try {
      r = await _api.postJsonWithRetry(
        AppConfig.ssoBase,
        Endpoints.idpRegisterSaveUserFirst,
        data: {
          'type': 0,
          'agreementId': _agreementId ?? '',
          'captchaVerifycation': captchaVerifycation,
          'attrMap': identityAttr,
        },
        options: DioOptions(
          contentType: 'application/json;charset=UTF-8',
          headers: {'Origin': 'https://sso.dzds.dz'},
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      print('[SSO] saveUserFirst HTTP error: $code');
      return SsoResult(
        false,
        code == 504
            ? 'server timeout (504) — the identity check did not respond in time. This is a server-side issue, please retry.'
            : 'server error ($code) — please retry.',
        {'code': '$code', 'httpError': true},
      );
    }
    print('[SSO] saveUserFirst response: $r');
    final data = r['data'];
    if (data is String && data.isNotEmpty) {
      _registerToken = data;
    }
    return SsoResult('${r['code']}' == '200', '${r['message'] ?? ''}', r);
  }

  /// Step 2 — submit account credentials + SMS code (using the token from
  /// [registerSaveUserFirst]) to actually create the account.
  Future<SsoResult> registerSaveUserSubmit(
      Map<String, dynamic> accountAttr) async {
    final data = <String, dynamic>{
      'type': 0,
      'agreementId': _agreementId ?? '',
      'attrMap': accountAttr,
    };
    final options = DioOptions(
      contentType: 'application/json;charset=UTF-8',
      headers: {'Origin': 'https://sso.dzds.dz'},
    );

    final results = await Future.wait(
      List.generate(
          _saveUserAttempts, (_) => _attemptSaveUserSubmit(data, options)),
    );

    // Prefer a definitive server answer (success or a specific error code) over
    // a gateway timeout (504/502/503).
    SsoResult? gateway;
    for (final r in results) {
      if (r.ok) return r;
      final code = '${r.data['code'] ?? ''}';
      if (code == '504' || code == '502' || code == '503') {
        gateway ??= r;
      } else {
        return r; // e.g. 30500 (bad password) or 201 (SMS expired)
      }
    }
    return gateway ?? results.last;
  }

  Future<SsoResult> _attemptSaveUserSubmit(
      Map<String, dynamic> data, DioOptions options) async {
    try {
      final r = await _api.postJson(
        AppConfig.ssoBase,
        Endpoints.idpRegisterSaveUserSubmit,
        data: data,
        options: options,
      );
      print('[SSO] saveUserSubmit response: $r');
      return SsoResult('${r['code']}' == '200', '${r['message'] ?? ''}', r);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      print('[SSO] saveUserSubmit HTTP error: $code');
      return SsoResult(
        false,
        code == 504
            ? 'server timeout (504) — the registration service did not respond in time. This is a server-side issue, not a problem with your information. Please retry later.'
            : 'server error ($code) — please retry.',
        {'code': '$code', 'httpError': true},
      );
    } catch (e) {
      print('[SSO] saveUserSubmit error: $e');
      return SsoResult(false, 'request error: $e', {'httpError': true});
    }
  }

  /// The token returned by [registerSaveUserFirst].
  String? get registerToken => _registerToken;

  String? get registerMobileToken => _registerMobileToken;

  String? get lck => _lck;

  String _ensureAbsolute(String url) =>
      url.startsWith('http') ? url : '${AppConfig.ssoBase}$url';

  String? _queryParam(String url, String key) {
    final normalized = url.split('#').last;
    final idx = normalized.indexOf('?');
    if (idx < 0) return null;
    for (final pair in normalized.substring(idx + 1).split('&')) {
      final kv = pair.split('=');
      if (kv.length == 2 && kv[0] == key) {
        return Uri.decodeQueryComponent(kv[1]);
      }
    }
    return null;
  }
}

