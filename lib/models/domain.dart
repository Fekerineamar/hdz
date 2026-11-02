// Domain models shared across the app.

/// Authenticated user, mirroring `/api/auth/session`.
class UserSession {
  final String id;
  final String name;
  final String username;
  final String realname;
  final String realnameAr;
  final String email;
  final String phone;
  final String card;
  final String realLevel;
  final String city;
  final String province;

  const UserSession({
    required this.id,
    required this.name,
    required this.username,
    required this.realname,
    required this.realnameAr,
    required this.email,
    required this.phone,
    required this.card,
    required this.realLevel,
    required this.city,
    required this.province,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final u = (json['user'] as Map<String, dynamic>?) ?? const {};
    final c = (u['companyInfo'] as Map<String, dynamic>?) ?? const {};
    return UserSession(
      id: '${u['id'] ?? ''}',
      name: '${u['name'] ?? ''}',
      username: '${u['username'] ?? ''}',
      realname: '${u['realname'] ?? ''}',
      realnameAr: '${u['realnameAr'] ?? ''}',
      email: '${u['email'] ?? c['email'] ?? ''}',
      phone: '${u['phone'] ?? c['phone'] ?? ''}',
      card: '${u['card'] ?? u['userCardNum'] ?? ''}',
      realLevel: '${u['reallevel'] ?? ''}',
      city: '${u['city'] ?? ''}',
      province: '${u['province'] ?? ''}',
    );
  }

  String get displayName => realnameAr.isNotEmpty ? realnameAr : realname;
}

/// Slider ("block puzzle") captcha payload returned by the SSO.
class CaptchaPuzzle {
  /// Background image (the larger one).
  final String originalImageBase64;

  /// Draggable jigsaw piece.
  final String jigsawImageBase64;

  /// Server token required to validate the slider answer.
  final String token;

  const CaptchaPuzzle({
    required this.originalImageBase64,
    required this.jigsawImageBase64,
    required this.token,
  });

  factory CaptchaPuzzle.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? const {};
    return CaptchaPuzzle(
      originalImageBase64: '${d['originalImageBase64'] ?? ''}',
      jigsawImageBase64: '${d['jigsawImageBase64'] ?? ''}',
      token: '${d['token'] ?? ''}',
    );
  }
}

/// A service the citizen can apply for.
class ServiceItem {
  final String unid;
  final String code;
  final String name;
  final String nameEn;
  final String deptName;
  final String description;

  const ServiceItem({
    required this.unid,
    required this.code,
    required this.name,
    this.nameEn = '',
    this.deptName = '',
    this.description = '',
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        unid: '${json['serviceUnid'] ?? json['unid'] ?? ''}',
        code: '${json['serviceCode'] ?? json['code'] ?? ''}',
        name: '${json['serviceName'] ?? json['name'] ?? ''}',
        nameEn: '${json['serviceNameEn'] ?? ''}',
        deptName: '${json['deptName'] ?? ''}',
        description: '${json['serviceDesc'] ?? ''}',
      );
}

/// A downloadable certificate / license.
class Certificate {
  final String identifier;
  final String licenseNumber;
  final String licenseName;
  final String licenseType;
  final String holder;
  final String dept;
  final String issueDate;
  final String validTimeEnd;
  final String state;

  const Certificate({
    required this.identifier,
    required this.licenseNumber,
    required this.licenseName,
    required this.licenseType,
    required this.holder,
    required this.dept,
    required this.issueDate,
    required this.validTimeEnd,
    required this.state,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
        identifier:
            '${json['licenseCode'] ?? json['certificateIdentifier'] ?? json['licenseId'] ?? ''}',
        licenseNumber: '${json['licenseNumber'] ?? ''}',
        licenseName: '${json['licenseName'] ?? ''}',
        licenseType: '${json['licenseType'] ?? ''}',
        holder: '${json['holder'] ?? ''}',
        dept: '${json['dept'] ?? ''}',
        issueDate: '${json['issueDate'] ?? ''}',
        validTimeEnd: '${json['validTimeEnd'] ?? ''}',
        state: '${json['state'] ?? ''}',
      );
}

/// Fields extracted from a photographed document (ID card, birth certificate…).
class DocumentData {
  final Map<String, String> fields;

  const DocumentData(this.fields);

  factory DocumentData.fromJson(Map<String, dynamic> json) =>
      DocumentData(json.map((k, v) => MapEntry(k, '$v')));

  String? get(String key) => fields[key];
}

/// Data required to create a new personal (natural-person) account.
///
/// Field names mirror the SSO `saveUser` `attrMap`. Values are human-readable
/// (e.g. `sex` = "male"/"female", `presumed` = "yes"/"no", `province`/`city`
/// are names) and are resolved to the server's dictionary ids at submit time.
class RegistrationData {
  // Account credentials.
  final String username;
  final String password;
  final String mobile;
  final String email;

  // Identity (documentTypeCode = 0, Algerian citizens).
  final String surnameAr;
  final String nameAr;
  final String surnameFr;
  final String nameFr;
  final String card; // NIN
  final String cni; // CNI number
  final String cniExpireDate; // YYYY-MM-DD
  final String presumed; // "yes" | "no"
  final String dateOfBirth; // YYYY-MM-DD
  final String sex; // "male" | "female"
  final String province; // wilaya name (ar/fr/en)
  final String city; // commune name (ar/fr/en)
  final String address; // optional

  const RegistrationData({
    required this.username,
    required this.password,
    required this.mobile,
    required this.email,
    required this.surnameAr,
    required this.nameAr,
    required this.surnameFr,
    required this.nameFr,
    required this.card,
    required this.cni,
    required this.cniExpireDate,
    required this.presumed,
    required this.dateOfBirth,
    required this.sex,
    required this.province,
    required this.city,
    this.address = '',
  });

  /// List of human-readable fields that are still missing.
  List<String> missingFields() {
    final out = <String>[];
    void check(String key, String value) {
      if (value.trim().isEmpty) out.add(key);
    }

    check('username', username);
    check('password', password);
    check('mobile', mobile);
    check('email', email);
    check('surname_ar', surnameAr);
    check('name_ar', nameAr);
    check('surname_fr', surnameFr);
    check('name_fr', nameFr);
    check('card', card);
    check('cni', cni);
    check('cni_expire_date', cniExpireDate);
    check('presumed', presumed);
    check('date_of_birth', dateOfBirth);
    check('sex', sex);
    check('province', province);
    check('city', city);
    return out;
  }
}
