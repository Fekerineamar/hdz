import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/storage/secure_store.dart';
import '../../models/domain.dart';
import '../auth/sms_service.dart';
import '../auth/sso_client.dart';
import '../services/portal_client.dart';

/// Human answer for a slider captcha.
class CaptchaAnswer {
  final double x;
  final double y;

  const CaptchaAnswer(this.x, this.y);
}

/// Callbacks the agent uses to pause and ask the human for input.
abstract class AgentHooks {
  void log(String message);
  Future<CaptchaAnswer> solveCaptcha(CaptchaPuzzle puzzle);
  Future<String> readSmsCode();
  Future<DocumentData?> provideDocument(String purpose);
}

/// The Gemini function-calling tool definitions.
List<FunctionDeclaration> buildToolDeclarations() => [
      FunctionDeclaration(
        'get_session',
        'Check whether the user is logged in to the DZDS portal.',
        Schema.object(properties: {}),
      ),
      FunctionDeclaration(
        'login',
        'Log the user in to the DZDS portal. Will ask the user to solve a '
        'slider captcha and to provide the SMS code automatically.',
        Schema.object(properties: {
          'username': Schema.string(description: 'Optional login username'),
          'password': Schema.string(description: 'Optional login password'),
        }),
      ),
      FunctionDeclaration(
        'list_services',
        'List available government services the citizen can apply for.',
        Schema.object(properties: {
          'query': Schema.string(description: 'Optional search text'),
        }),
      ),
      FunctionDeclaration(
        'get_service_guide',
        'Get the requirements / questions for a specific service so the user '
        'knows exactly what information and documents are needed to apply. '
        'Call this BEFORE start_application.',
        Schema.object(
          properties: {
            'service_unid': Schema.string(description: 'The service unid/code'),
          },
          requiredProperties: ['service_unid'],
        ),
      ),
      FunctionDeclaration(
        'start_application',
        'Start an application for a service and prepare its form. Ask the user '
        'any guide questions first (see get_service_guide) and pass their '
        'answers in answer_list.',
        Schema.object(
          properties: {
            'service_unid': Schema.string(description: 'The service unid/code'),
            'service_name': Schema.string(description: 'The service name'),
            'answer_list': Schema.array(
              description: 'Answers to the service guide questions, as a list '
                  'of answer codes (e.g. ["certificate_holder_rela_birth-1"]).',
              items: Schema.string(),
            ),
          },
          requiredProperties: ['service_unid'],
        ),
      ),
      FunctionDeclaration(
        'get_form_data',
        'Load the form structure (fields) for an application started with '
        'start_application. Pass the form_relation_id that start_application '
        'returned. This tells you exactly which fields the user must fill.',
        Schema.object(
          properties: {
            'form_relation_id': Schema.string(
                description: 'The form_relation_id from start_application'),
          },
          requiredProperties: ['form_relation_id'],
        ),
      ),
      FunctionDeclaration(
        'save_form',
        'Submit the filled form values for an application. Pass the ids from '
        'start_application and the user-filled values as a list of '
        '{code, value} pairs (code = the form component code from '
        'get_form_data).',
        Schema.object(
          properties: {
            'form_relation_id': Schema.string(
                description: 'The form_relation_id from start_application'),
            'instance_id': Schema.string(
                description: 'The instance_id from start_application'),
            'service_unid': Schema.string(
                description: 'The service_unid from start_application'),
            'values': Schema.array(
              description: 'Filled values as {code, value} pairs',
              items: Schema.object(
                properties: {
                  'code': Schema.string(
                      description: 'The form component code'),
                  'value': Schema.string(
                      description: 'The value filled by the user'),
                },
                requiredProperties: ['code', 'value'],
              ),
            ),
          },
          requiredProperties: [
            'form_relation_id',
            'instance_id',
            'service_unid',
            'values',
          ],
        ),
      ),
      FunctionDeclaration(
        'list_certificates',
        "List the user's electronic certificates.",
        Schema.object(properties: {}),
      ),
      FunctionDeclaration(
        'get_certificate',
        'Get the detail of one certificate.',
        Schema.object(
          properties: {
            'identifier': Schema.string(
                description: 'Certificate identifier / license id'),
          },
          requiredProperties: ['identifier'],
        ),
      ),
      FunctionDeclaration(
        'download_certificate',
        'Download a certificate PDF file.',
        Schema.object(
          properties: {
            'identifier': Schema.string(
                description: 'Certificate identifier / license id'),
          },
          requiredProperties: ['identifier'],
        ),
      ),
      FunctionDeclaration(
        'register',
        'Create a NEW DZDS personal account. Before calling this, ask the user '
        'for any fields they have not yet provided. The user may type the '
        'values directly, or send a photo of their ID card / birth certificate '
        'from which you extract the values. Resolve human-readable values '
        '(sex, presumed, province, city) to their names.',
        Schema.object(properties: {
          'username': Schema.string(
              description:
                  'Account login name (5-64 chars, letters+digits, at least one letter)'),
          'password': Schema.string(description: 'Account password'),
          'mobile': Schema.string(
              description: 'Mobile number, 10 digits starting with 0'),
          'email': Schema.string(description: 'Email address'),
          'surname_ar': Schema.string(description: 'Last name in Arabic'),
          'name_ar': Schema.string(description: 'First name in Arabic'),
          'surname_fr': Schema.string(description: 'Last name in Latin'),
          'name_fr': Schema.string(description: 'First name in Latin'),
          'card': Schema.string(
              description:
                  'NIN — 18-digit national identification number'),
          'cni': Schema.string(description: 'CNI card number'),
          'cni_expire_date':
              Schema.string(description: 'CNI expiration date YYYY-MM-DD'),
          'presumed': Schema.string(
              description: 'Is the date of birth presumed? "yes" or "no"'),
          'date_of_birth':
              Schema.string(description: 'Date of birth YYYY-MM-DD'),
          'sex': Schema.string(description: '"male" or "female"'),
          'province': Schema.string(
              description: 'Wilaya (province) of birth name, ar/fr/en'),
          'city': Schema.string(
              description: 'Commune (city) of birth name, ar/fr/en'),
          'address': Schema.string(description: 'Residential address (optional)'),
        }),
      ),
      FunctionDeclaration(
        'scan_document',
        'Ask the user to photograph an identity document (ID card, birth '
        'certificate, etc.) and return the extracted personal data. Use this '
        'when the user prefers to provide a document instead of typing fields.',
        Schema.object(properties: {
          'purpose': Schema.string(
              description: 'What the document is needed for, e.g. registration'),
        }),
      ),
    ];

/// The system prompt that turns Gemini into the portal agent.
const String agentSystemPrompt = '''
You are an intelligent assistant that operates the Algerian government digital services
portal (dzds.dz) on behalf of the user. You can call functions to
register a new account, log in, browse services, start applications, and manage electronic certificates.

Rules:
- Work step by step, one function call at a time, verifying the result of each call.
- If the user gives a username and/or password in their message, call `login` immediately with those values.

AUTO-REGISTRATION & AUTO-LOGIN FLOW:
- When document data has been extracted (both front and back sides):
  1. Auto-generate the username: lowercase Latin first name + last name (e.g. "amine_meziani" or "karim_bensalem").
  2. Auto-generate a secure password: e.g. "Dzds@2026!" or 8-16 characters with letters, digits, and a special character.
  3. Call `register` with all fields.
  4. Note that `register` will automatically log the user in upon creation!
  5. Once registered & logged in, ALWAYS output:
     username: <the_generated_username>
     password: <the_generated_password>
     and confirm in Arabic that registration and login are successful and the session is active.
     Then suggest one-click certificates (شهادة الميلاد, شهادة الإقامة, صحيفة السوابق القضائية, شهادة الجنسية...).

ALREADY REGISTERED HANDLING:
- If registration reports that the user, phone number, or national ID is already registered ('already_registered'):
  DO NOT treat this as a fatal failure.
  Immediately inform the user in friendly Arabic:
  "يبدو أن هذا الرقم / الحساب مسجّل بالفعل في منصة DZDS!
  الرجاء إدخال كلمة المرور الخاصة بك لتسجيل الدخول فوراً."
  When the user replies with their password, immediately call `login` using the extracted username or mobile number.

ONE-CLICK CERTIFICATE REQUESTS:
When the user clicks or asks to request any certificate (شهادات):
- 'شهادة الميلاد' (Birth Certificate): service_unid '000000200100010000', answer_list: ['certificate_holder_rela_birth-1'] (for self)
- 'وثيقة الإقامة ( شهادة / بطاقة )' (Residence): service_unid '000000200100040000'
- 'صحيفة السوابق القضائية' (Criminal Record): service_unid '000000200900010000'
- 'شهادة الجنسية' (Nationality): service_unid '000000200900020000'
- 'شهادة الزواج' (Marriage): service_unid '000000200100020000', answer_list: ['certificate_holder_rela_marriage-1']
- 'شهادة الإنتساب أو عدم الإنتساب CNAS': service_unid '000000200203010000'
- 'تسليم شهادة عدم الإنتساب CASNOS': service_unid '000000200201020000'
- 'شهادة عدم الخضوع للضريبة': service_unid '000000200302020000'

Process the certificate request immediately: start_application -> get_form_data -> save_form with user profile values.
Keep replies in Arabic, concise and professional.
''';

/// Executes tool calls by invoking the underlying portal / SSO clients.
class ToolExecutor {
  ToolExecutor({
    required SsoClient sso,
    required PortalClient portal,
    required SmsService sms,
    required AgentHooks hooks,
  })  : _sso = sso,
        _portal = portal,
        _sms = sms,
        _hooks = hooks;

  final SsoClient _sso;
  final PortalClient _portal;
  final SmsService _sms;
  final AgentHooks _hooks;

  final Map<String, String> _documentContext = {};

  // Registration SMS cache. The OTP is valid for 5 minutes, so a retry of the
  // (slow, 504-prone) `saveUser` step should reuse the already-sent code rather
  // than re-triggering a captcha + a new SMS.
  String? _regMobile;
  String? _regSmsCode;
  String? _regSmsToken;
  DateTime? _regSmsAt;

  Future<Map<String, Object?>> execute(FunctionCall call) async {
    final args = call.args;
    try {
      switch (call.name) {
        case 'get_session':
          return await _getSession();
        case 'login':
          return await _login(args);
        case 'list_services':
          return await _listServices(args);
        case 'get_service_guide':
          return await _getServiceGuide(args);
        case 'start_application':
          return await _startApplication(args);
        case 'get_form_data':
          return await _getFormData(args);
        case 'save_form':
          return await _saveForm(args);
        case 'list_certificates':
          return await _listCertificates();
        case 'get_certificate':
          return await _getCertificate(args);
        case 'download_certificate':
          return await _downloadCertificate(args);
        case 'register':
          return await _register(args);
        case 'scan_document':
          return await _scanDocument(args);
        default:
          return {'error': 'unknown tool ${call.name}'};
      }
    } catch (e) {
      return {'error': '$e'};
    }
  }

  Future<Map<String, Object?>> _getSession() async {
    final s = await _portal.session();
    if (s == null) return {'logged_in': false};
    return {
      'logged_in': true,
      'name': s.displayName,
      'username': s.username,
      'card': s.card,
      'phone': s.phone,
    };
  }

  Future<Map<String, Object?>> _login(Map<String, Object?> args) async {
    if (await _sso.hasSession()) {
      return {'logged_in': true, 'message': 'already logged in'};
    }

    final username =
        '${args['username'] ?? await SecureStore.instance.username ?? ''}';
    final password =
        '${args['password'] ?? await SecureStore.instance.password ?? ''}';

    if (username.isEmpty || password.isEmpty) {
      return {'needs': 'credentials', 'message': 'username/password required'};
    }

    _hooks.log('Starting SSO login…');
    final csrf = await _sso.getCsrfToken();
    final authorizeUrl = await _sso.startLogin(csrf);
    if (authorizeUrl.isEmpty) {
      return {'error': 'could not start login (no authorize URL)'};
    }
    await _sso.establishContext(authorizeUrl);
    await _sso.getSignature();
    await _sso.queryAuthMethods();

    // Validate username + password FIRST. The SMS must only be sent after the
    // credentials are confirmed valid (mirrors the real portal flow).
    await _sso.resolveAgreementId();
    final first =
        await _sso.authExecutePassword(loginName: username, password: password);
    if (!first.ok || _sso.requestNumber == null) {
      return {'error': 'invalid username or password: ${first.message}'};
    }

    // Credentials valid — now solve captcha and send the SMS code.
    final smsCode = await _obtainSmsCode(loginName: username);
    if (smsCode.isEmpty) {
      return {
        'error': 'no SMS code was provided (captcha or SMS send failed)',
        'hint': 'wait 2 minutes (cooling time) and try again',
      };
    }

    final second =
        await _sso.authExecuteSms(loginName: username, smsCode: smsCode);
    if (!_sso.hasLoginToken) {
      return {'error': 'SMS step failed: ${second.message}'};
    }

    final callbackUrl = await _sso.authnEngine();
    if (callbackUrl.isEmpty) {
      return {'error': 'no callback URL from auth engine'};
    }
    await _sso.completeCallback(callbackUrl);

    final s = await _portal.session();

    // The CAP service engine is privilege-protected: it asks for the password
    // to be re-entered (validate-user-license) before it will serve service /
    // certificate requests. Do it now, right after login, and persist the
    // password so PortalClient can transparently re-validate if the license
    // expires mid-run.
    if (s != null && password.isNotEmpty) {
      if ((await SecureStore.instance.password ?? '').isEmpty) {
        await SecureStore.instance.setPassword(password);
      }
      final lic = await _portal.validateUserLicense(password);
      _hooks.log(lic['flag'] == true
          ? 'Privileges validated'
          : 'Privilege validation: ${lic['message'] ?? lic['errorCode'] ?? 'failed'}');
    }

    return {
      'logged_in': s != null,
      'name': s?.displayName ?? '',
      'message': s != null ? 'logged in' : 'login incomplete',
    };
  }

  Future<Map<String, Object?>> _listServices(Map<String, Object?> args) async {
    final query = '${args['query'] ?? ''}';
    final services = await _portal.listServices(query: query);
    return {
      'query': query,
      'count': services.length,
      'services': services
          .map((s) => {
                'service_unid': s.unid,
                'name': s.name,
                'name_en': s.nameEn,
                'department': s.deptName,
                'description': s.description,
              })
          .toList(),
      'hint': 'To start a service, call start_application with the exact '
          'service_unid from the list above. Services with no guide questions '
          'redirect to an external portal.',
    };
  }

  Future<Map<String, Object?>> _getServiceGuide(Map<String, Object?> args) async {
    final unid = '${args['service_unid'] ?? ''}';
    if (unid.isEmpty) return {'error': 'service_unid is required'};

    final entry = _portal.catalogEntry(unid);
    final guide = _portal.serviceGuide(unid);

    // Prefer the bundled guide questions (fast, offline). Fall back to the
    // live service-scene config for portal-redirect / unknown services.
    if (guide.isNotEmpty) {
      return {
        'service_unid': unid,
        'service_name': entry?.nameAr ?? '',
        'service_name_en': entry?.nameEn ?? '',
        'description': entry?.description ?? '',
        'department': entry?.deptName ?? '',
        'questions': guide.map((q) {
          return {
            'question': q.name,
            'required': q.required,
            'answers': q.answers
                .map((a) => {'answer': a.name, 'code': a.code})
                .toList(),
          };
        }).toList(),
      };
    }

    final config = await _portal.serviceSceneConfig(unid);
    final data = PortalClient.dataAsMap(config);
    final base =
        Map<String, dynamic>.from((data['baseInfo'] as Map?) ?? const {});
    final questions = (data['questionList'] as List?) ?? const [];

    return {
      'service_unid': unid,
      'service_name': '${base['serviceName'] ?? entry?.nameAr ?? ''}',
      'description': '${base['serviceDesc'] ?? entry?.description ?? ''}',
      'department': '${base['deptName'] ?? entry?.deptName ?? ''}',
      'questions': questions.map((q) {
        final m = Map<String, dynamic>.from(q as Map);
        return {
          'question': '${m['name'] ?? ''}',
          'code': '${m['queCode'] ?? m['id'] ?? ''}',
          'required': '${m['required'] ?? 'N'}',
          'type': '${m['quesType'] ?? ''}',
          'answers': (m['answerList'] as List? ?? const [])
              .map((a) => Map<String, dynamic>.from(a as Map))
              .map((a) => {
                    'answer': '${a['name'] ?? a['code'] ?? ''}',
                    'code': '${a['code'] ?? ''}',
                  })
              .toList(),
        };
      }).toList(),
    };
  }

  Future<Map<String, Object?>> _startApplication(
      Map<String, Object?> args) async {
    final unid = '${args['service_unid'] ?? ''}';
    if (unid.isEmpty) return {'error': 'service_unid is required'};

    final answers = (args['answer_list'] as List?) ?? const [];
    final answerIds =
        answers.map((a) => '$a').where((a) => a.isNotEmpty).join(',');

    final scene = await _portal.createSceneInstance(unid, answerIds: answerIds);
    final data = PortalClient.dataAsMap(scene);
    final projid = '${data['projid'] ?? ''}';
    if (projid.isEmpty) {
      return {
        'error': 'could not start application: '
            '${scene['message'] ?? scene['fullMessage'] ?? 'unknown error'}',
        'detail': scene,
      };
    }
    final forms = (data['commForms'] as List?) ?? const [];
    final formList =
        forms.map((f) => Map<String, dynamic>.from(f as Map)).toList();

    // The form relation id is the `id` query param of the first form's URL.
    var formRelationId = '';
    var instanceId = '';
    if (formList.isNotEmpty) {
      final url = '${formList.first['yunFormUrl'] ?? ''}';
      formRelationId = _urlQueryParam(url, 'id');
      instanceId = _urlQueryParam(url, 'instanceId');
    }

    return {
      'projid': projid,
      'service_unid': unid,
      'form_count': formList.length,
      'form_relation_id': formRelationId,
      'instance_id': instanceId,
      'forms': formList
          .map((f) => {
                'form_name': f['formName'],
                'form_id': f['formId'],
                'yun_form_url': f['yunFormUrl'],
              })
          .toList(),
      'next': formRelationId.isNotEmpty
          ? 'call get_form_data with form_relation_id=$formRelationId'
          : null,
    };
  }

  Future<Map<String, Object?>> _getFormData(Map<String, Object?> args) async {
    final relationId = '${args['form_relation_id'] ?? ''}';
    if (relationId.isEmpty) return {'error': 'form_relation_id is required'};

    final rela = await _portal.formAffairRela(relationId);
    final relaData =
        PortalClient.dataAsMap(rela);
    final formId = '${relaData['form_id'] ?? ''}';
    final formTitle = '${relaData['form_title'] ?? ''}';
    if (formId.isEmpty) {
      return {'error': 'could not resolve form id', 'detail': rela};
    }

    final fd = await _portal.formData(formId);
    final fdData =
        PortalClient.dataAsMap(fd);
    final components = (fdData['form_components'] as List?) ?? const [];

    final fields = <Map<String, dynamic>>[];
    for (final c in components) {
      final comp =
          Map<String, dynamic>.from((c as Map)['component'] as Map);
      final m = Map<String, dynamic>.from(comp['meta'] as Map);
      fields.add({
        'label': '${m['label_name'] ?? ''}',
        'code': '${m['code'] ?? ''}',
        'type': '${m['type'] ?? ''}',
        'required': '${m['require'] ?? 'false'}',
        'hidden': '${m['hidden'] ?? 'false'}',
      });
    }

    return {
      'form_id': formId,
      'form_title': formTitle,
      'field_count': fields.length,
      'fields': fields,
    };
  }

  Future<Map<String, Object?>> _saveForm(Map<String, Object?> args) async {
    final relationId = '${args['form_relation_id'] ?? ''}';
    final instanceId = '${args['instance_id'] ?? ''}';
    final serviceUnid = '${args['service_unid'] ?? ''}';
    final values = (args['values'] as List?) ?? const [];

    if (relationId.isEmpty || instanceId.isEmpty || serviceUnid.isEmpty) {
      return {
        'error':
            'form_relation_id, instance_id and service_unid are required',
      };
    }

    // Map the user's {code, value} pairs.
    final valueByCode = <String, String>{};
    for (final v in values) {
      final m = Map<String, dynamic>.from(v as Map);
      valueByCode['${m['code']}'] = '${m['value']}';
    }

    final rela = await _portal.formAffairRela(relationId);
    final relaData =
        PortalClient.dataAsMap(rela);
    final formId = '${relaData['form_id'] ?? ''}';
    if (formId.isEmpty) {
      return {'error': 'could not resolve form id', 'detail': rela};
    }

    final fd = await _portal.formData(formId);
    final fdData =
        PortalClient.dataAsMap(fd);
    final components = (fdData['form_components'] as List?) ?? const [];

    final valueDtoList = <Map<String, dynamic>>[];
    for (final c in components) {
      final comp =
          Map<String, dynamic>.from((c as Map)['component'] as Map);
      final meta = Map<String, dynamic>.from(comp['meta'] as Map);
      final code = '${meta['code'] ?? ''}';
      final value = valueByCode[code];
      if (value == null || value.isEmpty) continue;
      valueDtoList.add({
        'unid': '${meta['id'] ?? ''}',
        'value': value,
        'hidden': meta['hidden'] ?? false,
        'require': meta['require'] ?? false,
        'fill_value': value,
        'fill_flag': true,
        'edit_method': meta['edit_method'] ?? '0',
      });
    }

    if (valueDtoList.isEmpty) {
      return {'error': 'no matching filled values for the form components'};
    }

    final res = await _portal.saveForm(
      serviceUnid: serviceUnid,
      instanceId: instanceId,
      valueDtoList: valueDtoList,
    );
    return {
      'result_code': '${res['result_code'] ?? ''}',
      'message': '${res['error_message'] ?? res['message'] ?? ''}',
      'detail': res,
    };
  }

  /// Extracts a query parameter value from a URL string.
  String _urlQueryParam(String url, String key) {
    final idx = url.indexOf('?');
    if (idx < 0) return '';
    for (final pair in url.substring(idx + 1).split('&')) {
      final kv = pair.split('=');
      if (kv.length == 2 && kv[0] == key) return Uri.decodeQueryComponent(kv[1]);
    }
    return '';
  }

  Future<Map<String, Object?>> _listCertificates() async {
    final list = await _portal.certificateList();
    return {
      'certificates': list
          .map((c) => {
                'identifier': c.identifier,
                'license_number': c.licenseNumber,
                'license_name': c.licenseName,
                'license_type': c.licenseType,
                'holder': c.holder,
                'issue_date': c.issueDate,
              })
          .toList(),
    };
  }

  Future<Map<String, Object?>> _getCertificate(
      Map<String, Object?> args) async {
    final identifier = '${args['identifier'] ?? ''}';
    if (identifier.isEmpty) return {'error': 'identifier is required'};
    return _portal.certificateDetail(identifier);
  }

  Future<Map<String, Object?>> _downloadCertificate(
      Map<String, Object?> args) async {
    final identifier = '${args['identifier'] ?? ''}';
    if (identifier.isEmpty) return {'error': 'identifier is required'};
    final bytes = await _portal.downloadCertificate(identifier);
    return {'downloaded': bytes.isNotEmpty, 'size': bytes.length};
  }

  Future<Map<String, Object?>> _register(Map<String, Object?> args) async {
    String s(String k, [List<String> fallbacks = const []]) {
      var val = '${args[k] ?? _documentContext[k] ?? ''}'.trim();
      if (val.isNotEmpty) return val;
      for (final fb in fallbacks) {
        val = '${args[fb] ?? _documentContext[fb] ?? ''}'.trim();
        if (val.isNotEmpty) return val;
      }
      return '';
    }

    final nameAr = s('name_ar', ['first_name_ar']);
    final surnameAr = s('surname_ar', ['last_name_ar']);
    final nameFr = s('name_fr', ['first_name_fr']);
    final surnameFr = s('surname_fr', ['last_name_fr']);

    // Auto-generate username if not provided
    var username = s('username');
    if (username.isEmpty && nameFr.isNotEmpty && surnameFr.isNotEmpty) {
      final cleanFirst = nameFr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final cleanLast = surnameFr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      username = '${cleanFirst}_$cleanLast';
      if (username.length < 5) username = '${username}_dz';
    }

    // Auto-generate password if not provided
    var password = s('password');
    if (password.isEmpty) {
      password = 'Dzds@${DateTime.now().year}!';
    }

    // Auto-generate email if not provided
    var email = s('email');
    if (email.isEmpty && username.isNotEmpty) {
      email = '$username@gmail.com';
    }

    // Mobile fallback to phone
    final mobile = s('mobile', ['phone']);

    // Sex normalization
    var sex = s('sex').toLowerCase();
    if (sex.contains('ذكر') || sex == 'm' || sex.contains('masculin') || sex.contains('male')) {
      sex = 'male';
    } else if (sex.contains('أنثى') || sex.contains('انثى') || sex == 'f' || sex.contains('feminin') || sex.contains('female')) {
      sex = 'female';
    } else if (sex.isEmpty) {
      sex = 'male';
    }

    // Presumed default to 'no'
    var presumed = s('presumed').toLowerCase();
    if (presumed.isEmpty || presumed.contains('لا') || presumed.contains('non')) {
      presumed = 'no';
    } else if (presumed.contains('نعم') || presumed.contains('oui')) {
      presumed = 'yes';
    }

    final data = RegistrationData(
      username: username,
      password: password,
      mobile: mobile,
      email: email,
      surnameAr: surnameAr,
      nameAr: nameAr,
      surnameFr: surnameFr,
      nameFr: nameFr,
      card: s('card', ['nin']),
      cni: s('cni', ['cni_number']),
      cniExpireDate: s('cni_expire_date'),
      presumed: presumed,
      dateOfBirth: s('date_of_birth', ['birth_date']),
      sex: sex,
      province: s('province', ['wilaya']),
      city: s('city', ['commune', 'birth_place']),
      address: s('address'),
    );

    final missing = data.missingFields();
    if (missing.isNotEmpty) {
      print('[REGISTER] missing fields: $missing');
      return {
        'needs': 'info',
        'missing_fields': missing,
        'message': 'Please provide: ${missing.join(', ')}',
      };
    }
    print('[REGISTER] username=${data.username} mobile=${data.mobile} '
        'email=${data.email} fr=${data.surnameFr}/${data.nameFr} '
        'presumed=${data.presumed} sex=${data.sex} '
        'province=${data.province} city=${data.city}');

    // Registration is its own SSO flow: always open a fresh authorize context
    // so we get a valid `lck` + `cookiesession1` (a stale login `lck` won't do).
    _hooks.log('Starting SSO registration…');
    final csrf = await _sso.getCsrfToken();
    final authorizeUrl = await _sso.startLogin(csrf);
    if (authorizeUrl.isEmpty) {
      return {'error': 'could not start registration (no authorize URL)'};
    }
    await _sso.establishContext(authorizeUrl);

    // Resolve human-readable dict values to server ids.
    final sexId = await _resolveDictId('gender', data.sex);
    if (sexId == null) return {'error': 'unknown gender "${data.sex}"'};
    final presumedId = await _resolveDictId('presumed', data.presumed);
    if (presumedId == null) {
      return {'error': 'unknown presumed value "${data.presumed}"'};
    }
    final provinceId = await _resolveDictId('province', data.province);
    if (provinceId == null) {
      return {'error': 'unknown province "${data.province}"'};
    }
    final cities = await _sso.registerCities(provinceId);
    final cityId = _matchId(cities, data.city);
    if (cityId == null) {
      return {
        'error': 'unknown city "${data.city}" in province "${data.province}"',
      };
    }

    // Agreement id is required by the registration endpoints.
    await _sso.resolveAgreementId();

    // STEP 1 — verify identity (slider captcha + saveUserFirst). The server
    // returns a registration token that the final submit step must echo back.
    _hooks.log('Verifying identity…');
    final captchaVerify = await _solveRegistrationCaptcha();
    if (captchaVerify == null) {
      return {'error': 'captcha for identity verification failed'};
    }
    final identityAttr = <String, dynamic>{
      'idCardType': '0',
      'presumed': presumedId,
      'date_of_birth': data.dateOfBirth,
      'legal_representative_birth_date': '',
      'surname_ar': data.surnameAr,
      'name_ar': data.nameAr,
      'surname_fr': data.surnameFr,
      'name_fr': data.nameFr,
      'card': data.card,
      'cni': data.cni,
      'cnibe_expire_date': data.cniExpireDate,
      'sex': sexId,
      'province': provinceId,
      'city': cityId,
    };
    final first = await _sso.registerSaveUserFirst(identityAttr, captchaVerify);
    if (!first.ok) {
      final code = '${first.data['code'] ?? ''}';
      final msg = first.message.toLowerCase();
      if (code == '30100' ||
          code == '30101' ||
          code == '30102' ||
          code == '30103' ||
          msg.contains('exist') ||
          msg.contains('موجود') ||
          msg.contains('مسجل') ||
          msg.contains('déjà')) {
        return {
          'already_registered': true,
          'error': 'already_registered',
          'phone': data.mobile,
          'message': 'المستخدم أو رقم الهاتف مسجل بالفعل في منصة DZDS.',
          'hint': 'اطلب من المستخدم كلمة المرور لتسجيل الدخول مباشرة.',
        };
      }
      final hint = _registrationHint(code);
      return {
        'error': 'identity verification failed: ${first.message}',
        if (hint.isNotEmpty) 'hint': hint,
        'detail': first.data,
      };
    }

    // STEP 2 — mobile verification code. A previously obtained code for the
    // same number is reused while it is still valid, so a retry does NOT
    // resend the SMS.
    final sms = await _obtainRegistrationSms(data.mobile);
    final smsCode = sms.code;
    final smsToken = sms.token;
    if (smsCode.isEmpty) {
      return {
        'error': 'no SMS code was provided (captcha or SMS send failed)',
        'hint': 'wait 2 minutes (cooling time) and try again',
      };
    }

    // STEP 3 — submit the account (token + credentials + SMS code).
    final accountAttr = <String, dynamic>{
      'token': _sso.registerToken ?? '',
      'mail': {'address': data.email},
      'user_name': data.username,
      'password': data.password,
      'mobile': {
        'address': data.mobile,
        'mobileVerifyCode': smsCode,
        'token': smsToken,
      },
    };
    final res = await _sso.registerSaveUserSubmit(accountAttr);
    if (!res.ok) {
      final code = '${res.data['code'] ?? ''}';
      final msg = res.message.toLowerCase();
      if (code == '30100' ||
          code == '30101' ||
          msg.contains('exist') ||
          msg.contains('موجود') ||
          msg.contains('مسجل')) {
        return {
          'already_registered': true,
          'error': 'already_registered',
          'phone': data.mobile,
          'message': 'رقم الهاتف أو الحساب مسجل بالفعل في منصة DZDS.',
          'hint': 'اطلب من المستخدم كلمة المرور لتسجيل الدخول مباشرة.',
        };
      }
      if (code == '201') {
        // The server says the SMS code expired — drop the cache so the next
        // attempt sends a fresh code.
        _regMobile = null;
        _regSmsCode = null;
        _regSmsToken = null;
        _regSmsAt = null;
      }
      final hint = _registrationHint(code);
      return {
        'error': 'registration failed: ${res.message}',
        if (hint.isNotEmpty) 'hint': hint,
        'detail': res.data,
      };
    }

    final dataMap = (res.data['data'] as Map?) ?? const {};
    var realLevelUrl = '${dataMap['realLevelUrl'] ?? ''}';
    // Newer responses return realLevelUrl as a JSON string {"web":…,"H5":…}.
    if (realLevelUrl.startsWith('{')) {
      try {
        final parsed = jsonDecode(realLevelUrl) as Map<String, dynamic>;
        realLevelUrl = '${parsed['web'] ?? parsed['H5'] ?? ''}';
      } catch (_) {}
    }

    // Save generated credentials
    await SecureStore.instance.setUsername(data.username);
    await SecureStore.instance.setPassword(data.password);

    _hooks.log('تم إنشاء الحساب بنجاح! جاري تسجيل الدخول التلقائي…');
    Map<String, Object?> loginResult = {};
    try {
      loginResult = await _login({
        'username': data.username,
        'password': data.password,
      });
    } catch (e) {
      _hooks.log('تنبيه في تسجيل الدخول التلقائي: $e');
    }

    return {
      'registered': true,
      'username': data.username,
      'password': data.password,
      'logged_in': loginResult['logged_in'] == true,
      'real_level_url': realLevelUrl,
      'message': 'account created and auto-login executed',
    };
  }

  /// Solves a slider captcha for the identity step and returns the
  /// `captchaVerifycation` value (`token---pointJson`), or null on failure.
  Future<String?> _solveRegistrationCaptcha() async {
    final puzzle = await _sso.registerCaptcha();
    _hooks.log('Waiting for captcha…');
    final answer = await _hooks.solveCaptcha(puzzle);
    if (!await _sso.checkCaptcha(answer.x, answer.y)) {
      _hooks.log('Captcha rejected');
      return null;
    }
    return _sso.captchaVerifycation(answer.x, answer.y);
  }

  /// Translates a `saveUser` error code into a human-readable hint that tells
  /// the user whether the failure is their data or the server.
  String _registrationHint(String code) {
    switch (code) {
      case '30200':
        return 'Identity verification failed: the personal info does not '
            'match the ID card exactly. Double-check the NIN, CNI number, '
            'name, date of birth and CNI expiry date.';
      case '201':
        return 'The SMS verification code expired. Restart and use a fresh code.';
      case '30500':
        return 'The password does not meet the policy (e.g. it must be 8-20 '
            'characters). Shorten/adjust it and retry.';
      case '504':
      case '502':
      case '503':
        return 'Server-side timeout — this is not a problem with your '
            'information. Retry later.';
      default:
        return '';
    }
  }

  /// Returns the registration SMS code + its server token, reusing a cached
  /// code for the same mobile number while it is still valid (5 minutes). This
  /// prevents a registration retry (e.g. after a 504 server timeout) from
  /// re-triggering the captcha and re-sending an SMS.
  Future<({String code, String token})> _obtainRegistrationSms(
      String mobile) async {
    final now = DateTime.now();
    final cached = _regSmsCode;
    if (cached != null &&
        cached.isNotEmpty &&
        _regMobile == mobile &&
        _regSmsAt != null &&
        now.difference(_regSmsAt!) < const Duration(minutes: 5)) {
      _hooks.log('Reusing the existing SMS code (still valid)…');
      return (code: cached, token: _regSmsToken ?? '');
    }

    final code = await _obtainSmsCode(receiver: mobile);
    if (code.isEmpty) return (code: '', token: '');
    _regMobile = mobile;
    _regSmsCode = code;
    _regSmsToken = _sso.registerMobileToken ?? '';
    _regSmsAt = DateTime.now();
    return (code: code, token: _regSmsToken!);
  }

  /// Runs the captcha → send-SMS → read-code loop. If the user taps "Resend"
  /// (the SMS dialog returns `__RESEND__`), re-runs the captcha + SMS send.
  /// Returns the entered code, or '' on failure.
  Future<String> _obtainSmsCode({String? loginName, String? receiver}) async {
    while (true) {
      final puzzle = receiver != null
          ? await _sso.registerCaptcha()
          : await _sso.getCaptchaPuzzle();
      _hooks.log('Waiting for captcha…');
      final answer = await _hooks.solveCaptcha(puzzle);
      if (!await _sso.checkCaptcha(answer.x, answer.y)) {
        _hooks.log('Captcha rejected');
        return '';
      }

      final send = receiver != null
          ? await _sso.registerSendSecurityCode(receiver, answer.x, answer.y)
          : await _sso.sendSms(loginName!, answer.x, answer.y);
      if (!send.ok) {
        _hooks.log('SMS send failed: ${send.message}');
        return '';
      }

      _hooks.log('Waiting for SMS code…');
      await _sms.requestPermission();
      final code = await _hooks.readSmsCode();
      if (code == '__RESEND__') {
        _hooks.log('Resending SMS code…');
        continue;
      }
      return code;
    }
  }

  /// Resolves a human-readable dictionary value to its server id.
  Future<String?> _resolveDictId(String dictCode, String value) async {
    final list = await _sso.registerDict(dictCode);
    return _matchId(list, value);
  }

  Future<Map<String, Object?>> _scanDocument(Map<String, Object?> args) async {
    final purpose = '${args['purpose'] ?? 'registration'}';
    _hooks.log('Waiting for document photo…');
    final data = await _hooks.provideDocument(purpose);
    if (data == null) return {'error': 'no document was provided'};
    return {
      'document_type': data.fields['document_type'] ?? '',
      'fields': data.fields,
    };
  }

  /// Matches a value against a dict/list entry's names and returns its id.
  String? _matchId(List<Map<String, dynamic>> list, String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;
    for (final item in list) {
      final candidates = <String>[
        '${item['value']}',
        '${item['valueArDz']}',
        '${item['valueEnUs']}',
        '${item['valueFrFr']}',
        '${item['name']}',
      ];
      for (final c in candidates) {
        if (c.trim().toLowerCase() == v) return '${item['id']}';
      }
    }
    // Fall back to matching the raw id itself.
    for (final item in list) {
      if ('${item['id']}' == value.trim()) return '${item['id']}';
    }
    return null;
  }

  /// Seeds the document context with extracted fields.
  void seedDocumentContext(DocumentData data) {
    _documentContext.addAll(data.fields);
  }

  Map<String, String> get documentContext =>
      Map.unmodifiable(_documentContext);
}
