import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/secure_store.dart';
import '../../features/agent/agent_controller.dart';
import '../../features/ai/tools.dart';
import '../../features/auth/sms_service.dart';
import '../../models/domain.dart';
import '../widgets/captcha_dialog.dart';
import '../widgets/credentials_card.dart';
import '../widgets/sms_dialog.dart';
import 'certificates_screen.dart';
import 'settings_screen.dart';

// ---------------------------------------------------------------------------
// Chat session model
// ---------------------------------------------------------------------------

class _ChatSession {
  _ChatSession(this.id, this.agent);

  final int id;
  final AgentController agent;
  final List<_ChatItem> messages = [];
  StreamSubscription<AgentEvent>? sub;
  String title = 'محادثة جديدة';
  bool busy = false;
  bool dialogOpen = false;

  /// Active status message (e.g. Thinking..., Running...) while agent is running.
  String? activeStatus;

  /// Active user session if logged in.
  UserSession? userSession;

  /// If registration succeeded, store generated credentials.
  _Credentials? credentials;

  /// Last known certificate list.
  List<Certificate> certificates = [];

  /// Stored document data from ID card extraction, so we never re-ask for images.
  DocumentData? extractedDocument;
}

class _Credentials {
  const _Credentials({required this.username, required this.password});
  final String username;
  final String password;
}

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatSession> _chats = [];
  int _active = 0;
  int _nextId = 1;

  _ChatSession get _chat => _chats[_active];

  @override
  void initState() {
    super.initState();
    SmsService.instance.start();
    final session = _ChatSession(_nextId++, AgentController());
    session.sub = session.agent.events.listen((e) => _onEvent(session, e));
    _chats.add(session);
    _active = 0;
    // Check if a session already exists on startup
    session.agent.checkSession();
  }

  @override
  void dispose() {
    for (final c in _chats) {
      c.sub?.cancel();
      c.agent.dispose();
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Chat management
  // -------------------------------------------------------------------------

  _ChatSession _newChat() {
    final session = _ChatSession(_nextId++, AgentController());
    session.sub = session.agent.events.listen((e) => _onEvent(session, e));
    setState(() {
      _chats.add(session);
      _active = _chats.length - 1;
    });
    session.agent.checkSession();
    return session;
  }

  void _switchChat(int index) {
    if (index == _active) return;
    setState(() => _active = index);
    _chat.agent.checkSession();
  }

  void _deleteChat(int index) {
    final session = _chats[index];
    session.sub?.cancel();
    session.agent.dispose();
    setState(() {
      _chats.removeAt(index);
      if (_chats.isEmpty) {
        final s = _ChatSession(_nextId++, AgentController());
        s.sub = s.agent.events.listen((e) => _onEvent(s, e));
        _chats.add(s);
        _active = 0;
        s.agent.checkSession();
      } else if (_active >= _chats.length) {
        _active = _chats.length - 1;
      }
    });
  }

  // -------------------------------------------------------------------------
  // Event handling
  // -------------------------------------------------------------------------

  void _onEvent(_ChatSession session, AgentEvent event) {
    if (!mounted) return;
    switch (event) {
      case AgentSessionUpdated():
        setState(() {
          session.userSession = event.session;
        });
      case AgentMessage():
        _add(session, _ChatItem.agent(event.text));
        _tryParseCredentials(session, event.text);
        _checkAlreadyRegistered(session, event.text);
      case AgentStatus():
        setState(() {
          session.activeStatus = event.text.isNotEmpty ? event.text : null;
        });
      case AgentNeedCaptcha():
        _showCaptcha(session, event.puzzle);
      case AgentNeedSms():
        _showSms(session);
      case AgentNeedDocument():
        if (session.extractedDocument != null) {
          session.agent.resolveDocument(session.extractedDocument);
        } else {
          _pickBothSidesDocument(session);
        }
      case AgentDone():
        setState(() {
          session.activeStatus = null;
        });
        if (event.text.trim().isNotEmpty) {
          _add(session, _ChatItem.agent(event.text));
          _tryParseCredentials(session, event.text);
          _checkAlreadyRegistered(session, event.text);
        }
        _setBusy(session, false);
        session.agent.checkSession();
      case AgentError():
        setState(() {
          session.activeStatus = null;
        });
        _add(session, _ChatItem.error(event.text));
        _checkAlreadyRegistered(session, event.text);
        _setBusy(session, false);
    }
  }

  /// Detect auto-generated credentials in agent reply and surface the card.
  void _tryParseCredentials(_ChatSession session, String text) {
    final userMatch = RegExp(
      r'(?:username|اسم المستخدم)[:\s]+([A-Za-z0-9_.\-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    final passMatch = RegExp(
      r'(?:password|كلمة المرور)[:\s]+(\S+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (userMatch != null && passMatch != null) {
      setState(() {
        session.credentials = _Credentials(
          username: userMatch.group(1) ?? '',
          password: passMatch.group(1) ?? '',
        );
      });
    }
  }

  /// Detect if already registered and prompt password dialog if needed.
  void _checkAlreadyRegistered(_ChatSession session, String text) {
    if (text.contains('already_registered') ||
        text.contains('مسجّل بالفعل') ||
        text.contains('مسجل بالفعل') ||
        text.contains('الحساب مسجل مسبقاً')) {
      // Show password prompt dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !session.busy && session.userSession == null) {
          _promptLoginPassword(session);
        }
      });
    }
  }

  void _promptLoginPassword(_ChatSession session) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('الحساب مسجل مسبقاً'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هذا الرقم أو الهوية مسجلة بالفعل في منصة DZDS.\nيرجى إدخال كلمة المرور لتسجيل الدخول مباشرة:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.login_rounded),
            label: const Text('تسجيل الدخول'),
            onPressed: () {
              final pass = passController.text.trim();
              Navigator.pop(ctx);
              if (pass.isNotEmpty) {
                _add(session, _ChatItem.user('كلمة المرور الخاصة بي: ••••••••'));
                _setBusy(session, true);
                session.agent.start('كلمة المرور الخاصة بي هي: $pass. سجّل الدخول فوراً.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _add(_ChatSession session, _ChatItem item) {
    if (!mounted) return;
    setState(() {
      session.messages.add(item);
      if (session.title == 'محادثة جديدة' && item.kind == _Kind.user) {
        final t = item.text.trim();
        session.title = t.length > 30 ? '${t.substring(0, 30)}…' : t;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setBusy(_ChatSession session, bool v) {
    if (!mounted) return;
    setState(() {
      session.busy = v;
      if (!v) session.activeStatus = null;
    });
  }

  // -------------------------------------------------------------------------
  // User actions
  // -------------------------------------------------------------------------

  bool _isCertificateOrServiceRequest(String text) {
    final lower = text.toLowerCase();
    final keywords = [
      'شهادة', 'استخراج', 'سوابق', 'ميلاد', 'إقامة', 'اقامة', 
      'جنسية', 'انتساب', 'بطاقة', 'عقد', 'وثيقة', 'cnas', 'casnos',
      'عدم الانتساب', 'عدم الإنتساب', 'الضرائب', 'ضريبة', 'طلب'
    ];
    return keywords.any((k) => lower.contains(k));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chat.busy) return;
    _controller.clear();
    _add(_chat, _ChatItem.user(text));

    final isLoggedIn = _chat.userSession != null;
    final savedUsername = await SecureStore.instance.username ?? '';
    final savedPassword = await SecureStore.instance.password ?? '';

    // If NOT logged in and NO saved credentials:
    if (!isLoggedIn && (savedUsername.isEmpty || savedPassword.isEmpty)) {
      if (_isCertificateOrServiceRequest(text)) {
        if (_chat.extractedDocument != null && _chat.extractedDocument!.fields.isNotEmpty) {
          _add(_chat, _ChatItem.agent(
            'تتوفر لدينا بيانات بطاقة التعريف الخاصة بك بالفعل! جاري إتمام التسجيل وتأكيد الحساب لمتابعة طلبك…',
          ));
          _executeRegistrationFlow(_chat.extractedDocument!.fields);
          return;
        }
        _add(_chat, _ChatItem.authPrompt(
          title: 'يلزم بطاقة التعريف لاستخراج الوثائق',
          text: 'لاستخراج الوثائق والشهادات الرسمية فوراً، يرجى رفع بطاقة التعريف الوطنية (الواجهتين) ليتم استخراج بياناتك وإنشاء حسابك والدخول تلقائياً، أو تسجيل الدخول بحسابك.',
          onUpload: () => _uploadAndRegisterBothSides(),
          onLogin: () => _promptLoginPassword(_chat),
        ));
        return;
      }
    }

    _setBusy(_chat, true);
    if (!isLoggedIn && savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      _chat.agent.start(
        '$text (الحساب المحفوظ في النظام: اسم المستخدم $savedUsername وكلمة المرور $savedPassword. سجّل الدخول بهما مباشرة).',
      );
    } else {
      _chat.agent.start(text);
    }
  }

  void _stop() {
    _chat.agent.stop();
    if (_chat.dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _setBusy(_chat, false);
    _add(_chat, _ChatItem.agent('تم إيقاف المساعد.'));
  }

  // -------------------------------------------------------------------------
  // One-click certificate request
  // -------------------------------------------------------------------------

  Future<void> _requestCertificate(String name, String unid) async {
    if (_chat.busy) return;

    final isLoggedIn = _chat.userSession != null;
    final savedUsername = await SecureStore.instance.username ?? '';
    final savedPassword = await SecureStore.instance.password ?? '';

    // Case 1: NOT logged in and NO saved credentials -> Zero-latency Code Prompt (No Gemini waste!)
    if (!isLoggedIn && (savedUsername.isEmpty || savedPassword.isEmpty)) {
      _add(_chat, _ChatItem.user('أريد استخراج $name لنفسي فوراً'));
      if (_chat.extractedDocument != null && _chat.extractedDocument!.fields.isNotEmpty) {
        _add(_chat, _ChatItem.agent(
          'تتوفر لدينا بيانات بطاقة التعريف الخاصة بك بالفعل! جاري إتمام التسجيل وتأكيد الحساب لاستخراج $name فوراً…',
        ));
        await _executeRegistrationFlow(_chat.extractedDocument!.fields);
        return;
      }
      _add(_chat, _ChatItem.authPrompt(
        title: 'يلزم بطاقة التعريف لاستخراج $name',
        text: 'لاستخراج $name فوراً عبر منصة DZDS الرسمية، يرجى رفع بطاقة التعريف الوطنية (الوجهين) ليقوم المساعد بإنشاء حسابك وتوليد بيانات الدخول تلقائياً، أو تسجيل الدخول إذا كنت مسجلاً مسبقاً.',
        onUpload: () => _uploadAndRegisterBothSides(),
        onLogin: () => _promptLoginPassword(_chat),
      ));
      return;
    }

    // Case 2: NOT logged in, but HAS saved credentials in SecureStore -> Auto-login with cert
    if (!isLoggedIn && savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
      _add(_chat, _ChatItem.user('أريد استخراج $name لنفسي فوراً'));
      _setBusy(_chat, true);
      _chat.agent.start(
        'استخرج $name (service_unid: $unid) لنفسي فوراً. '
        'قم أولاً بتسجيل الدخول الفوري بالحساب المحفوظ (اسم المستخدم: $savedUsername، كلمة المرور: $savedPassword) ثم استخرج الشهادة فوراً.',
      );
      return;
    }

    // Case 3: Already logged in -> Instant cert fetch
    _add(_chat, _ChatItem.user('أريد استخراج $name لنفسي فوراً'));
    _setBusy(_chat, true);
    _chat.agent.start('أريد استخراج $name (service_unid: $unid) لنفسي فوراً.');
  }

  // -------------------------------------------------------------------------
  // Direct Both Sides Document Upload & Auto-Registration Flow
  // -------------------------------------------------------------------------

  Map<String, String> _normalizeDocumentFields(Map<String, String> raw) {
    final out = Map<String, String>.from(raw);
    String pick(String k, List<String> fbs) {
      if (out[k] != null && out[k]!.trim().isNotEmpty) return out[k]!.trim();
      for (final fb in fbs) {
        if (out[fb] != null && out[fb]!.trim().isNotEmpty) return out[fb]!.trim();
      }
      return '';
    }

    final nameAr = pick('name_ar', ['first_name_ar']);
    final surnameAr = pick('surname_ar', ['last_name_ar']);
    final nameFr = pick('name_fr', ['first_name_fr']);
    final surnameFr = pick('surname_fr', ['last_name_fr']);
    final card = pick('card', ['nin']);
    final cni = pick('cni', ['cni_number']);
    final cniExpire = pick('cni_expire_date', []);
    final dob = pick('date_of_birth', ['birth_date']);
    final province = pick('province', ['wilaya']);
    final city = pick('city', ['commune', 'birth_place']);
    final mobile = pick('mobile', ['phone']);
    final address = pick('address', []);
    final fatherName = pick('father_name', []);
    final motherName = pick('mother_name', []);

    // Username auto-generation
    var username = pick('username', []);
    if (username.isEmpty && nameFr.isNotEmpty && surnameFr.isNotEmpty) {
      final cleanFirst = nameFr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final cleanLast = surnameFr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      username = '${cleanFirst}_$cleanLast';
      if (username.length < 5) username = '${username}_dz';
    }

    // Password auto-generation
    var password = pick('password', []);
    if (password.isEmpty) {
      password = 'Dzds@${DateTime.now().year}!';
    }

    // Email auto-generation
    var email = pick('email', []);
    if (email.isEmpty && username.isNotEmpty) {
      email = '$username@gmail.com';
    }

    // Sex normalization
    var sex = pick('sex', []).toLowerCase();
    if (sex.contains('ذكر') || sex == 'm' || sex.contains('masculin') || sex.contains('male')) {
      sex = 'male';
    } else if (sex.contains('أنثى') || sex.contains('انثى') || sex == 'f' || sex.contains('feminin') || sex.contains('female')) {
      sex = 'female';
    } else if (sex.isEmpty) {
      sex = 'male';
    }

    // Presumed
    var presumed = pick('presumed', []).toLowerCase();
    if (presumed.isEmpty || presumed.contains('لا') || presumed.contains('non')) {
      presumed = 'no';
    } else if (presumed.contains('نعم') || presumed.contains('oui')) {
      presumed = 'yes';
    }

    out['name_ar'] = nameAr;
    out['surname_ar'] = surnameAr;
    out['name_fr'] = nameFr;
    out['surname_fr'] = surnameFr;
    out['card'] = card;
    out['cni'] = cni;
    out['cni_expire_date'] = cniExpire;
    out['date_of_birth'] = dob;
    out['province'] = province;
    out['city'] = city;
    out['mobile'] = mobile;
    out['address'] = address;
    out['username'] = username;
    out['password'] = password;
    out['email'] = email;
    out['sex'] = sex;
    out['presumed'] = presumed;
    if (fatherName.isNotEmpty) out['father_name'] = fatherName;
    if (motherName.isNotEmpty) out['mother_name'] = motherName;

    return out;
  }

  Future<String?> _promptPhoneNumber() async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_android_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('رقم الهاتف للتسجيل', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تم استخراج بيانات بطاقة الهوية بنجاح! يلزم رقم الهاتف لتلقي رمز التفعيل SMS وإتمام التسجيل فوراً.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (05 / 06 / 07)',
                hintText: '06XXXXXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('متابعة التسجيل'),
            onPressed: () {
              final val = c.text.trim();
              Navigator.pop(ctx, val.isNotEmpty ? val : null);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAndRegisterBothSides() async {
    if (_chat.busy) return;

    final phoneController = TextEditingController();
    final savedPhone = await SecureStore.instance.username ?? '';
    if (savedPhone.startsWith('0') && savedPhone.length == 10) {
      phoneController.text = savedPhone;
    }

    if (!mounted) return;

    // Show stylish sheet to pick both sides & enter phone
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'رفع وثيقة الهوية (الوجهين معاً)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'التقط أو اختر وجهي البطاقة (أمامي + خلفي) ليتم استخراج البيانات والتسجيل التلقائي فوراً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 16),

              // Phone number input for SMS code
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف لتلقي رمز SMS (اختياري الآن)',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(),
                  hintText: '06XXXXXXXX',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Method 1: Camera capture both sides (Front then Back)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('تصوير الوجهين بالكاميرا (أمامي ثم خلفي)'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _captureBothSidesFromCamera(phoneController.text.trim());
                },
              ),
              const SizedBox(height: 10),

              // Method 2: Gallery multi-select (Front + Back)
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('اختيار الصورتين معاً من المعرض (أمامي + خلفي)'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _pickBothSidesFromGallery(phoneController.text.trim());
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureBothSidesFromCamera(String phone) async {
    // 1. Front Side
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الرجاء تصوير الوجه الأمامي لبطاقة الهوية'),
        duration: Duration(seconds: 2),
      ),
    );
    final frontFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (frontFile == null) return;

    // 2. Back Side
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ممتاز! الآن صوّر الوجه الخلفي للبطاقة'),
        duration: Duration(seconds: 2),
      ),
    );
    final backFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);

    final frontBytes = await frontFile.readAsBytes();
    final backBytes = backFile != null ? await backFile.readAsBytes() : null;

    final images = <Uint8List>[frontBytes];
    if (backBytes != null) images.add(backBytes);

    await _processBothSidesImages(images, phone);
  }

  Future<void> _pickBothSidesFromGallery(String phone) async {
    final files = await _picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;

    final images = <Uint8List>[];
    for (final f in files) {
      images.add(await f.readAsBytes());
    }

    await _processBothSidesImages(images, phone);
  }

  Future<void> _processBothSidesImages(List<Uint8List> images, String initialPhone) async {
    if (images.isEmpty) return;

    _add(_chat, _ChatItem.user(
      images.length > 1
          ? '📷 تم إرفاق صورة الوجهين (أمامي وخلفي) للبطاقة'
          : '📷 تم إرفاق صورة الوثيقة',
    ));
    _setBusy(_chat, true);

    setState(() {
      _chat.activeStatus = 'جاري استخراج البيانات من الوجهين بواسطة الذكاء الاصطناعي…';
    });

    try {
      final data = await _chat.agent.extractDocument(
        multipleBytes: images,
        mimeType: 'image/jpeg',
      );

      if (data.fields.isEmpty) {
        _setBusy(_chat, false);
        _add(_chat, _ChatItem.error('لم نتمكن من قراءة البيانات من الصور. يرجى التأكد من وضوح الإضاءة وجودة الصورة وإعادة المحاولة.'));
        return;
      }

      var fields = _normalizeDocumentFields(data.fields);

      // Handle phone number
      var phone = initialPhone.trim();
      if (phone.isEmpty && (fields['mobile'] == null || fields['mobile']!.isEmpty)) {
        final saved = await SecureStore.instance.username ?? '';
        if (saved.startsWith('0') && saved.length == 10) {
          phone = saved;
        }
      }

      if (phone.isEmpty && (fields['mobile'] == null || fields['mobile']!.isEmpty)) {
        setState(() => _chat.activeStatus = null);
        final promptPhone = await _promptPhoneNumber();
        if (promptPhone != null && promptPhone.isNotEmpty) {
          phone = promptPhone;
        }
      }

      if (phone.isNotEmpty) {
        fields['mobile'] = phone;
      }

      // Re-normalize with phone
      fields = _normalizeDocumentFields(fields);

      // Store in session so it is NEVER lost
      _chat.extractedDocument = DocumentData(fields);
      _chat.agent.seedDocument(_chat.extractedDocument!);

      // Display clean summary
      final displayName = '${fields['name_ar']} ${fields['surname_ar']}'.trim();
      final displayNameFr = '${fields['name_fr']} ${fields['surname_fr']}'.trim();
      _add(_chat, _ChatItem.agent(
        '✅ تم استخراج كافة البيانات بنجاح من الوجهين:\n'
        '• الاسم واللقب: $displayName ($displayNameFr)\n'
        '• رقم التعريف الوطني NIN: ${fields['card']}\n'
        '• رقم بطاقة التعريف CNI: ${fields['cni']}\n'
        '• تاريخ الميلاد: ${fields['date_of_birth']} (${fields['province']})\n'
        '• رقم الهاتف: ${fields['mobile']}\n\n'
        'جاري إنشاء الحساب وإرسال طلب التسجيل فوراً…',
      ));

      // Direct, fast registration execution
      await _executeRegistrationFlow(fields);
    } catch (e) {
      _setBusy(_chat, false);
      _add(_chat, _ChatItem.error('خطأ أثناء قراءة الوثيقة: $e'));
    }
  }

  Future<void> _executeRegistrationFlow(Map<String, String> fields) async {
    _setBusy(_chat, true);
    setState(() {
      _chat.activeStatus = 'جاري التحقق من الهوية وإرسال طلب التسجيل…';
    });

    try {
      final res = await _chat.agent.executeRegistration(fields);
      setState(() => _chat.activeStatus = null);

      if (res['already_registered'] == true) {
        _setBusy(_chat, false);
        _add(_chat, _ChatItem.agent('الحساب أو رقم الهاتف مسجل بالفعل في منصة DZDS! يرجى إدخال كلمة المرور لتسجيل الدخول فوراً.'));
        _promptLoginPassword(_chat);
        return;
      }

      if (res['registered'] == true) {
        final uname = '${res['username'] ?? fields['username']}';
        final pass = '${res['password'] ?? fields['password']}';
        setState(() {
          _chat.credentials = _Credentials(username: uname, password: pass);
        });
        _setBusy(_chat, false);
        _add(_chat, _ChatItem.agent(
          '🎉 تم إنشاء الحساب بنجاح وتوليد بيانات الدخول:\n'
          'اسم المستخدم: $uname\n'
          'كلمة المرور: $pass\n\n'
          'تم تسجيل الدخول بنجاح والجلسة نشطة الآن. يمكنك الآن استخراج أي شهادة أو خدمة حكومية بنقرة واحدة من الشريط أدناه!',
        ));
        _chat.agent.checkSession();
        return;
      }

      // If registration failed (500 or identity verification error, etc.)
      _setBusy(_chat, false);
      final errorMsg = '${res['error'] ?? 'حدث خطأ أثناء التسجيل'}';
      final hint = res['hint']?.toString();
      _add(_chat, _ChatItem.error('تعذر إتمام التسجيل تلقائياً: $errorMsg'));

      // Pop up editable details modal so user can fix and retry!
      _showEditDetailsModal(fields, errorMsg, hint: hint);
    } catch (e) {
      _setBusy(_chat, false);
      _add(_chat, _ChatItem.error('خطأ في الاتصال: $e'));
      _showEditDetailsModal(fields, '$e');
    }
  }

  void _showEditDetailsModal(Map<String, String> currentFields, String errorMsg, {String? hint}) {
    final nameArCtrl = TextEditingController(text: currentFields['name_ar'] ?? '');
    final surnameArCtrl = TextEditingController(text: currentFields['surname_ar'] ?? '');
    final nameFrCtrl = TextEditingController(text: currentFields['name_fr'] ?? '');
    final surnameFrCtrl = TextEditingController(text: currentFields['surname_fr'] ?? '');
    final cardCtrl = TextEditingController(text: currentFields['card'] ?? '');
    final cniCtrl = TextEditingController(text: currentFields['cni'] ?? '');
    final cniExpireCtrl = TextEditingController(text: currentFields['cni_expire_date'] ?? '');
    final dobCtrl = TextEditingController(text: currentFields['date_of_birth'] ?? '');
    final provinceCtrl = TextEditingController(text: currentFields['province'] ?? '');
    final cityCtrl = TextEditingController(text: currentFields['city'] ?? '');
    final mobileCtrl = TextEditingController(text: currentFields['mobile'] ?? '');
    String selectedSex = currentFields['sex'] == 'female' ? 'female' : 'male';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: Colors.blue, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'مراجعة وتعديل بيانات التسجيل',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Error notification banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade400, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            const Text(
                              'تنبيه أثناء التحقق من الخادم',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hint ?? errorMsg,
                          style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'يرجى مراجعة وتصحيح الحقول أدناه ثم الضغط على "إعادة إرسال طلب التسجيل":',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Form Fields
                  Expanded(
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameArCtrl,
                                decoration: const InputDecoration(labelText: 'الاسم (بالعربية)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: surnameArCtrl,
                                decoration: const InputDecoration(labelText: 'اللقب (بالعربية)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameFrCtrl,
                                decoration: const InputDecoration(labelText: 'Prénom (Latin)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: surnameFrCtrl,
                                decoration: const InputDecoration(labelText: 'Nom (Latin)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cardCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'رقم التعريف الوطني NIN (18 رقماً)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cniCtrl,
                                decoration: const InputDecoration(labelText: 'رقم بطاقة CNI (9 أرقام)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: cniExpireCtrl,
                                decoration: const InputDecoration(labelText: 'تاريخ انتهاء CNI (YYYY-MM-DD)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dobCtrl,
                                decoration: const InputDecoration(labelText: 'تاريخ الميلاد (YYYY-MM-DD)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedSex,
                                decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'male', child: Text('ذكر (Male)')),
                                  DropdownMenuItem(value: 'female', child: Text('أنثى (Female)')),
                                ],
                                onChanged: (v) => setModalState(() => selectedSex = v ?? 'male'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: provinceCtrl,
                                decoration: const InputDecoration(labelText: 'الولاية (Province)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: cityCtrl,
                                decoration: const InputDecoration(labelText: 'البلدية (City)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف (05 / 06 / 07)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.phone_android_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Bottom action buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('إعادة إرسال طلب التسجيل'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final updated = Map<String, String>.from(currentFields);
                            updated['name_ar'] = nameArCtrl.text.trim();
                            updated['surname_ar'] = surnameArCtrl.text.trim();
                            updated['name_fr'] = nameFrCtrl.text.trim();
                            updated['surname_fr'] = surnameFrCtrl.text.trim();
                            updated['card'] = cardCtrl.text.trim();
                            updated['cni'] = cniCtrl.text.trim();
                            updated['cni_expire_date'] = cniExpireCtrl.text.trim();
                            updated['date_of_birth'] = dobCtrl.text.trim();
                            updated['province'] = provinceCtrl.text.trim();
                            updated['city'] = cityCtrl.text.trim();
                            updated['mobile'] = mobileCtrl.text.trim();
                            updated['sex'] = selectedSex;

                            final normalized = _normalizeDocumentFields(updated);
                            _chat.extractedDocument = DocumentData(normalized);
                            _chat.agent.seedDocument(_chat.extractedDocument!);
                            _executeRegistrationFlow(normalized);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBothSidesDocument(_ChatSession session) async {
    await _uploadAndRegisterBothSides();
  }

  // -------------------------------------------------------------------------
  // Dialogs
  // -------------------------------------------------------------------------

  Future<void> _showCaptcha(_ChatSession session, CaptchaPuzzle puzzle) async {
    session.dialogOpen = true;
    final answer = await showDialog<CaptchaAnswer>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CaptchaDialog(puzzle: puzzle),
    );
    session.dialogOpen = false;
    session.agent.resolveCaptcha(answer?.x ?? 0, answer?.y ?? 0);
  }

  Future<void> _showSms(_ChatSession session) async {
    session.dialogOpen = true;
    final codeSub = SmsService.instance.codes.listen((code) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(code);
      }
    });
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SmsDialog(),
    );
    session.dialogOpen = false;
    await codeSub.cancel();
    session.agent.resolveSms(code ?? '');
  }

  // -------------------------------------------------------------------------
  // Certificates Screen & Profile Dialog
  // -------------------------------------------------------------------------

  void _openCertificates() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificatesScreen(
          certificates: _chat.certificates,
          onRequestCertificate: (name, unid) => _requestCertificate(name, unid),
        ),
      ),
    );
  }

  void _showUserProfileSheet() {
    final user = _chat.userSession;
    if (user == null) {
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('غير مسجل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('قم برفع بطاقة الهوية للتسجيل التلقائي أو تسجيل الدخول.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('تسجيل الدخول'),
                  onPressed: () {
                    Navigator.pop(context);
                    _controller.text = 'سجّل الدخول';
                    _send();
                  },
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            const Text('جلسة نشطة (متصل)', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _ProfileItem(icon: Icons.person_outline, label: 'اسم المستخدم', value: user.username),
              if (user.card.isNotEmpty) _ProfileItem(icon: Icons.badge_outlined, label: 'رقم التعريف الوطني NIN', value: user.card),
              if (user.phone.isNotEmpty) _ProfileItem(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: user.phone),
              if (user.province.isNotEmpty) _ProfileItem(icon: Icons.location_on_outlined, label: 'الولاية / المدينة', value: '${user.province} ${user.city}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: const Text('شهاداتي'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openCertificates();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text('خروج', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _chat.userSession = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الخروج')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(scheme),
      body: Column(
        children: [
          // If credentials were newly generated
          if (_chat.credentials != null)
            CredentialsCard(
              username: _chat.credentials!.username,
              password: _chat.credentials!.password,
              onDismiss: () => setState(() => _chat.credentials = null),
            ),

          // Chat messages or welcome view
          Expanded(
            child: _chat.messages.isEmpty
                ? _buildWelcomeScreen(scheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: _chat.messages.length + (_chat.busy && _chat.activeStatus != null ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i < _chat.messages.length) {
                        return _chat.messages[i].build(context);
                      }
                      return _buildActiveStatusIndicator(scheme, _chat.activeStatus!);
                    },
                  ),
          ),

          // Quick 1-click certificates horizontal ribbon
          _buildCertificatesRibbon(scheme),

          // Busy loader
          if (_chat.busy)
            LinearProgressIndicator(
              minHeight: 2,
              color: scheme.primary,
              backgroundColor: scheme.primaryContainer,
            ),

          // Bottom composer
          _buildComposer(scheme),
        ],
      ),
    );
  }

  Widget _buildActiveStatusIndicator(ColorScheme scheme, String statusText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: scheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Certificates One-Click Horizontal Ribbon
  // -------------------------------------------------------------------------

  Widget _buildCertificatesRibbon(ColorScheme scheme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withOpacity(0.3), width: 0.5),
          bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: popularCertificates.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == popularCertificates.length) {
            return ActionChip(
              avatar: const Icon(Icons.more_horiz_rounded, size: 16),
              label: const Text('جميع الشهادات', style: TextStyle(fontSize: 12)),
              onPressed: _openCertificates,
            );
          }
          final c = popularCertificates[i];
          return ActionChip(
            avatar: Text(c.icon),
            label: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            backgroundColor: scheme.surfaceContainerHighest,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _requestCertificate(c.name, c.serviceUnid),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Welcome screen
  // -------------------------------------------------------------------------

  Widget _buildWelcomeScreen(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.assistant_rounded, size: 40, color: scheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'منصة الخدمات الرقمية DZDS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'المساعد الذكي لاستخراج الشهادات والخدمات الحكومية بنقرة واحدة.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Big direct upload action
          Card(
            elevation: 0,
            color: scheme.primaryContainer.withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _uploadAndRegisterBothSides,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.primary,
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'رفع بطاقة الهوية (الوجهين معاً)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'استخراج فوري للبيانات، تسجيل الحساب وتسجيل الدخول التلقائي',
                            style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick certificate request tiles
          _QuickAction(
            icon: Icons.flash_on_rounded,
            color: Colors.amber.shade800,
            title: 'طلب شهادة الميلاد بنقرة واحدة',
            subtitle: 'استخراج فوري لشهادة الميلاد عبر الخدمة الرسمية',
            onTap: () => _requestCertificate('شهادة الميلاد', '000000200100010000'),
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.gavel_rounded,
            color: Colors.indigo,
            title: 'صحيفة السوابق القضائية',
            subtitle: 'طلب واستخراج القسيمة رقم 3 مباشرة',
            onTap: () => _requestCertificate('صحيفة السوابق القضائية', '000000200900010000'),
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.workspace_premium_rounded,
            color: scheme.tertiary,
            title: 'قائمة الشهادات الإلكترونية',
            subtitle: 'عرض كافة الشهادات الرسمية المتاحة للطلب الفوري',
            onTap: _openCertificates,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AppBar with Logged-in Favicon / Avatar Indicator
  // -------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    final scheme = Theme.of(context).colorScheme;
    final user = _chat.userSession;
    final isLoggedIn = user != null;

    return AppBar(
      title: Text(_chat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      centerTitle: true,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'المحادثات',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        // User profile avatar / favicon indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showUserProfileSheet,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: isLoggedIn ? Colors.green.shade700 : scheme.surfaceContainerHighest,
                    child: Text(
                      isLoggedIn && user.displayName.isNotEmpty
                          ? user.displayName[0]
                          : '؟',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLoggedIn ? Colors.white : scheme.outline,
                      ),
                    ),
                  ),
                  // Logged-in Favicon Dot Badge
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isLoggedIn ? Colors.greenAccent.shade400 : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Certificates button
        IconButton(
          icon: const Icon(Icons.workspace_premium_outlined),
          tooltip: 'الشهادات',
          onPressed: _openCertificates,
        ),

        // New chat button
        IconButton(
          icon: const Icon(Icons.add_comment_outlined),
          tooltip: 'محادثة جديدة',
          onPressed: _newChat,
        ),

        // Settings button
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'الإعدادات',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Drawer
  // -------------------------------------------------------------------------

  Widget _buildDrawer(ColorScheme scheme) {
    final user = _chat.userSession;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primaryContainer),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary,
                  radius: 24,
                  child: Icon(Icons.assistant_rounded, color: scheme.onPrimary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user != null ? user.displayName : 'DZDS Agent',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.onPrimaryContainer),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user != null ? 'متصل: ${user.username}' : 'المساعد الرقمي الجزائري',
                        style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('محادثة جديدة'),
                onPressed: () {
                  Navigator.pop(context);
                  _newChat();
                },
              ),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'المحادثات',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (_, i) {
                final c = _chats[i];
                return ListTile(
                  selected: i == _active,
                  selectedTileColor: scheme.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: i == _active ? scheme.primary : null,
                  ),
                  title: Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _switchChat(i);
                  },
                  trailing: _chats.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          tooltip: 'حذف',
                          onPressed: () => _deleteChat(i),
                        )
                      : null,
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('الشهادات والوثائق'),
            onTap: () {
              Navigator.pop(context);
              _openCertificates();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Composer
  // -------------------------------------------------------------------------

  Widget _buildComposer(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            // Direct Both Sides Upload Button
            _ComposerBtn(
              icon: Icons.document_scanner_rounded,
              tooltip: 'رفع وثيقة الهوية (الوجهين معاً)',
              color: scheme.primary,
              onPressed: _chat.busy ? null : _uploadAndRegisterBothSides,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة أو اطلب شهادة…',
                  hintStyle: TextStyle(color: scheme.outline),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            if (_chat.busy)
              _ComposerBtn(
                icon: Icons.stop_circle_rounded,
                tooltip: 'إيقاف',
                color: scheme.error,
                onPressed: _stop,
              )
            else
              _ComposerBtn(
                icon: Icons.send_rounded,
                tooltip: 'إرسال',
                color: scheme.primary,
                onPressed: _send,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.outline),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontSize: 13, color: scheme.outline)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerBtn extends StatelessWidget {
  const _ComposerBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.filled(
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey.shade300 : color,
          foregroundColor: Colors.white,
          fixedSize: const Size(44, 44),
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat item
// ---------------------------------------------------------------------------

enum _Kind { user, agent, error, authPrompt }

class _ChatItem {
  final _Kind kind;
  final String text;
  final String? title;
  final VoidCallback? onUpload;
  final VoidCallback? onLogin;

  _ChatItem.user(this.text)
      : kind = _Kind.user,
        title = null,
        onUpload = null,
        onLogin = null;

  _ChatItem.agent(this.text)
      : kind = _Kind.agent,
        title = null,
        onUpload = null,
        onLogin = null;

  _ChatItem.error(this.text)
      : kind = _Kind.error,
        title = null,
        onUpload = null,
        onLogin = null;

  _ChatItem.authPrompt({
    required this.title,
    required this.text,
    required this.onUpload,
    required this.onLogin,
  }) : kind = _Kind.authPrompt;

  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (kind) {
      case _Kind.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(text, style: TextStyle(color: scheme.onPrimary, fontSize: 14)),
          ),
        );

      case _Kind.agent:
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.assistant_rounded, size: 16, color: scheme.primary),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(text, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        );

      case _Kind.error:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.error.withOpacity(0.3), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Flexible(
                child: Text(text, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13)),
              ),
            ],
          ),
        );

      case _Kind.authPrompt:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withOpacity(0.35), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.badge_rounded, size: 18, color: scheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title ?? 'يلزم بطاقة التعريف الوطنية',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.document_scanner_rounded, size: 18),
                  label: const Text('رفع بطاقة التعريف (الواجهتين) الآن'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('تسجيل الدخول بحساب مسجّل مسبقاً'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
