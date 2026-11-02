// AUTO-GENERATED from the dzds.dz public service catalog (smp-service-list-query
// + service-scene-config-get). Do not edit by hand — regenerate instead.
// Total services: 64

/// A guide question the user must answer before starting an application.
class ServiceGuideQuestion {
  final String name;
  final bool required;
  final List<ServiceGuideAnswer> answers;
  const ServiceGuideQuestion(this.name, this.required, this.answers);
}

/// A selectable answer for a guide question.
class ServiceGuideAnswer {
  final String name;
  final String code;
  const ServiceGuideAnswer(this.name, this.code);
}

/// Full catalog entry (name translations + department + description).
class ServiceCatalogEntry {
  final String unid;
  final String nameAr;
  final String nameEn;
  final String deptName;
  final String description;
  const ServiceCatalogEntry({
    required this.unid, required this.nameAr, required this.nameEn,
    required this.deptName, this.description = '',
  });
}

/// Arabic service name -> serviceUnid (full catalog).
const Map<String, String> serviceCatalog = {
  'شهادة الميلاد': '000000200100010000',
  'شهادة الزواج': '000000200100020000',
  'شهادة الوفاة': '000000200100030000',
  'شهادة الإنتساب أو عدم الإنتساب CNAS.': '000000200203010000',
  'طلب الإنتساب إلى CASNOS': '000000200201010000',
  'تسليم شهادة عدم الإنتساب CASNOS': '000000200201020000',
  'شهادة عدم تقاضي امتياز التقاعد': '000000200204020000',
  'شهادة الدخل': '000000200204010000',
  'بطاقة عقارية': '000000200301030000',
  'منحة البطالة': '000000200202010000',
  'مستخرج الجداول': '000000200302010000',
  'شهادة عدم الخضوع للضريبة': '000000200302020000',
  'شهادة الوجود C20': '000000200302030000',
  'شهادة الترقيم الجبائي (شخص طبيعي)': '000000200302040000',
  'طلب جديد للبطاقة المهنية للفلاح': '000000200700010001',
  'شهادة الترقيم الجبائي-  (شخص معنوي)': '000000200302050000',
  'طلب الإعتراف بالشهادات الأجنبية و منح المعادلة': '000000201300010000',
  'بطاقة العائلية': '000000200100050000',
  'صحيفة السوابق القضائية': '000000200900010000',
  'طلب التقاعد لغير المؤمن عليهم ( التقاعد الإلكتروني )': '000000200204030000',
  'شهادة الجنسية': '000000200900020000',
  'النيابة الإلكترونية': '000000200900030000',
  'رخصة الإتصال بمحبوس': '000000200900040000',
  'طلب موعد فحص طبي متخصص': '000000201200010000',
  'نسخة من عقد الملكية': '000000200301040000',
  'وثيقة الإقامة ( شهادة  / بطاقة )': '000000200100040000',
  'بطاقة ترقيم المركبات': '000000200100060000',
  'طلب التسجيل في السنة الأولى ابتدائي': '000000201100010000',
  'بطاقة الشخص ذي الاحتياجات الخاصة': '000000200500010001',
  'تعديل بطاقة الشخص ذي الاحتياجات الخاصة': '000000200500010002',
  'مستخرج حالة قسمCC12': '000000200301020000',
  'المنحة الجزافية للتضامن': '000000200500020001',
  'دفتر عقاري': '000000200301010000',
  'تعديل بطاقة المنحة الجزافية للتضامن': '000000200500020002',
  'الحصول على الهوية الرقمية': '000000200100070000',
  'رخصة البناء الالكترونية': '000000200400010000',
  'الربط بشبكة الماء الشروب': '000000201400010000',
  'الربط  بشبكة التطهير العمومية': '000000201400020000',
  'طلب معلومات (موجزة )': '000000200301050000',
  'إعادة الإصدار في حالة فقدان أو تلف بطاقة المنحة الجزافية للتضامن': '000000200500020003',
  'فضاء الأولياء': '000000201100020000',
  'إسند CREG': '000000201501010000',
  'محاكاة فاتورتي CREG': '000000201501020000',
  'الدفع الإلكتروني SONELGAZ': '000000201502010000',
  'أبوستيل': '000000200000010000',
  'اعادة إصدار بطاقة الشخص ذي الاحتياجات الخاصة': '000000200500010003',
  'إطاقتي SONELGAZ': '000000201502020000',
  'إلتماس CREG': '000000201501030000',
  'إترشيد': '000000201503010000',
  'الخدمات الرقمية للحج': '000000201601010000',
  'بوابة الخدمات العمومية لوزارة الأشغال العمومية والمنشآت القاعدية': '000000201700010000',
  'البوابة الإلكترونية لشهادات التأهيل و التصنيف المهنيين': '000000201400030000',
  'تسجيل طالبي التكوين': '000000201900010000',
  'وظيفتي': '000000202000010000',
  'الخدمة الإلكترونية لإدارة المسابقات القرآنية الوطنية': '000000201601040000',
  'انخراطي': '000000202100010000',
  'شراكة': '000000202100020000',
  'مخيمي': '000000202100030000',
  'تكوين': '000000202100040000',
  'مهرجاني': '000000202100050000',
  'القادة الشباب': '000000202100060000',
  'حركية': '000000202100070000',
  'مقرأة إلكترونية': '000000201601050000',
  'البوابة الجزائرية للعمرة': '000000201601020000',
};

/// Per-service metadata (unid -> entry).
const Map<String, ServiceCatalogEntry> serviceCatalogMeta = {
  '000000200100010000': ServiceCatalogEntry(unid: '000000200100010000', nameAr: 'شهادة الميلاد', nameEn: 'Birth Certificate', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: 'خدمة  للمواطنين الجزائريين تتيح طلب شهادة ميلاد لإثبات ميلاد شخص.'),
  '000000200100020000': ServiceCatalogEntry(unid: '000000200100020000', nameAr: 'شهادة الزواج', nameEn: 'Marriage Certificate', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: 'خدمة للمواطنين الجزائريين للتقدم بطلب للحصول على شهادات الزواج لإثبات الحالة الاجتماعية للشخص.'),
  '000000200100030000': ServiceCatalogEntry(unid: '000000200100030000', nameAr: 'شهادة الوفاة', nameEn: 'Death Certificate', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: 'خدمة للمواطنين الجزائريين لطلب شهادات الوفاة لإثبات حالة وفاة الشخص.'),
  '000000200203010000': ServiceCatalogEntry(unid: '000000200203010000', nameAr: 'شهادة الإنتساب أو عدم الإنتساب CNAS.', nameEn: 'Certificate of affiliation or non affiliation to CNAS', deptName: 'الصندوق الوطني للضمان الاجتماعي', description: 'تتيح هذه الخدمة للمواطنين طلب و إستخراج شهادة الإنتساب أو عدم الإنتساب إلى الضمان الاجتماعي.'),
  '000000200201010000': ServiceCatalogEntry(unid: '000000200201010000', nameAr: 'طلب الإنتساب إلى CASNOS', nameEn: 'Affiliation for non-employees (CASNOS)', deptName: 'الصندوق الوطني للضمان الاجتماعي لغير الأجراء', description: 'خدمة مخصصة للعمال غير الأجراء وجميع العاملين لحسابهم الخاص، ولا سيما قادة المشاريع والشركات الصغيرة والحرفيين وأولئك الذين يمارسون مهنًا بسيطة، غير المنتسبين بعد للصندوق الوطني للضمان الاجتماعي لغير الاجراء والذين يرغبون في الاستفادة من التغطية الاجتماعية التي يقدمها الصندوق.'),
  '000000200201020000': ServiceCatalogEntry(unid: '000000200201020000', nameAr: 'تسليم شهادة عدم الإنتساب CASNOS', nameEn: 'Non Affiliation CASNOS', deptName: 'الصندوق الوطني للضمان الاجتماعي لغير الأجراء', description: 'صُممت هذه الخدمة لإصدار شهادة عدم الانتساب للأشخاص الذين لا يعملون لحسابهم الخاص وغير المنتسبين إلى CASNOS.'),
  '000000200204020000': ServiceCatalogEntry(unid: '000000200204020000', nameAr: 'شهادة عدم تقاضي امتياز التقاعد', nameEn: 'Certificate of non-receipt', deptName: 'الصندوق الوطني للتقاعد', description: 'شهادة عدم تقاضي امتياز التقاعد هي وثيقة رسمية صالحة لمدة ثلاثة أشهر، يصدرها الصندوق الوطني للتقاعد، وتثبت أن الشخص لا يستفيد من اي إمتياز أو دخل من الصندوق. وهذه الوثيقة حاسمة بالنسبة لبعض الإجراءات الإدارية التي يكون فيها إثبات عدم الإمتياز ضرورياً لتحديد الأهلية للحصول على استحقاقات معينة، مثل المساعدة الاجتماعية، أو طلب السكن الاجتماعي.'),
  '000000200204010000': ServiceCatalogEntry(unid: '000000200204010000', nameAr: 'شهادة الدخل', nameEn: 'Certificate of income', deptName: 'الصندوق الوطني للتقاعد', description: 'شهادة الدخل :  وثيقة رسمية يصدرها الصندوق الوطني للتقاعد، تؤكد وضع المتقاعد ومبلغ معاشه\nوتشكل هذه الشهادة إثباتا لمقدم الطلب. وغالباً ما يكون مطلوباً لمختلف الإجراءات الإدارية أو المالية،  مثل طلبات التأشيرة، أو طلبات الإسكان وما إلى ذلك. وبالإضافة إلى ذلك، من الضروري أيضا تحديد أهلية الشخص للحصول على استحقاقات اجتماعية معينة.'),
  '000000200301030000': ServiceCatalogEntry(unid: '000000200301030000', nameAr: 'بطاقة عقارية', nameEn: 'Property card', deptName: 'المديرية العامة للأملاك الوطنية', description: ''),
  '000000200202010000': ServiceCatalogEntry(unid: '000000200202010000', nameAr: 'منحة البطالة', nameEn: 'Unemployment Allowance', deptName: 'الوكالة الوطنية للتشغيل', description: 'منحة البطالة هو برنامج يهدف إلى مرافقة وتحفيز ودعم الباحثين عن عمل لأول مرة .'),
  '000000200302010000': ServiceCatalogEntry(unid: '000000200302010000', nameAr: 'مستخرج الجداول', nameEn: 'Assessment Notice', deptName: 'المديرية العامة للضرائب', description: 'مستخرج الجداول هي وثيقة صادرة من طرف قابض الضرائب بطلب من المكلف بالضريبة و التي تحتوي على وضعيته الجبائية'),
  '000000200302020000': ServiceCatalogEntry(unid: '000000200302020000', nameAr: 'شهادة عدم الخضوع للضريبة', nameEn: 'Tax Free Certificate', deptName: 'المديرية العامة للضرائب', description: ''),
  '000000200302030000': ServiceCatalogEntry(unid: '000000200302030000', nameAr: 'شهادة الوجود C20', nameEn: 'Certificate of existence C20', deptName: 'المديرية العامة للضرائب', description: 'شهادة الوجود هي وثيقة تصدرها مصالح الوعاء الضريبي التابعة لمديرية الضرائب (مفتشية الضرائب , المراكز الجو ارية للضرائب , مراكز   ضر ائب ومديرية كبريات  المؤسسات) بعد اكتمال اجراءات التصريح المنصوص عليها في احكام المادة 183 من قانون الضرائب المباشرة والرسوم المماثل'),
  '000000200302040000': ServiceCatalogEntry(unid: '000000200302040000', nameAr: 'شهادة الترقيم الجبائي (شخص طبيعي)', nameEn: 'Tax Registration Certificate – NIF (Natural Person)', deptName: 'المديرية العامة للضرائب', description: ''),
  '000000200700010001': ServiceCatalogEntry(unid: '000000200700010001', nameAr: 'طلب جديد للبطاقة المهنية للفلاح', nameEn: 'New application for professional farmer card', deptName: 'الغرفة الوطنية للفلاحة', description: 'البطاقة المهنية هي اعتراف بصفة الفلاح بموجب المرسوم التنفيذي رقم 63-96 المؤرخ في 27 جانفي 1996 الذي يعرف النشاطات الفلاحية و يحدد شروط و كيفيات الاعتراف بصفة الفلاح  و القرار المؤرخ في 25 ماي 1996، المعدل، الذي يحدد كيفيات تسجيل الفلاحين، مسك السجلات المتعلقة بهم و نموذج البطاقة المهنية للفلاح.'),
  '000000200302050000': ServiceCatalogEntry(unid: '000000200302050000', nameAr: 'شهادة الترقيم الجبائي-  (شخص معنوي)', nameEn: 'Tax Registration Certificate – NIF (Legal Entity)', deptName: 'المديرية العامة للضرائب', description: ''),
  '000000201300010000': ServiceCatalogEntry(unid: '000000201300010000', nameAr: 'طلب الإعتراف بالشهادات الأجنبية و منح المعادلة', nameEn: 'Request for Recognition of Foreign Degrees and Issuance of Equivalency', deptName: 'وزارة التعليم العالي و البحث العلمي', description: ''),
  '000000200100050000': ServiceCatalogEntry(unid: '000000200100050000', nameAr: 'بطاقة العائلية', nameEn: 'Family certificate', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: 'البطاقة العائلية للحالة المدنية هي وثيقة رسمية صادرة عن مصالح الحالة المدنية للبلدية، تتضمن ملخص الدفتر العائلي (عقود ميلاد الزوجين، تاريخ ومكان زواجهما) وكذا ملخص عقود ميلاد الأبناء (اللقب والاسم وتاريخ ومكان ميلادهم).\n تستخدم هذه الوثيقة في مختلف الإجراءات الإدارية، لاسيما في ملفات المتعلقة بطلبات الاستفادة من الخدمات الاجتماعية والتسجيلات المدرسية والإجراءات مع مختلف الهيئات والمؤسسات  .\nملاحظة: يتعين القيام بتسجيل أولي  في الملف الوطني للأسر على مستوى البلدية في حالة عدم تمكنك من الحصول على البطاقة العائلية (لمرة واحدة فقط)'),
  '000000200900010000': ServiceCatalogEntry(unid: '000000200900010000', nameAr: 'صحيفة السوابق القضائية', nameEn: 'Criminal record', deptName: 'وزارة العدل', description: ''),
  '000000200204030000': ServiceCatalogEntry(unid: '000000200204030000', nameAr: 'طلب التقاعد لغير المؤمن عليهم ( التقاعد الإلكتروني )', nameEn: 'Online retirement application for inactive policyholders (electronic retirement)', deptName: 'الصندوق الوطني للتقاعد', description: ''),
  '000000200900020000': ServiceCatalogEntry(unid: '000000200900020000', nameAr: 'شهادة الجنسية', nameEn: 'Nationality certificate', deptName: 'وزارة العدل', description: ''),
  '000000200900030000': ServiceCatalogEntry(unid: '000000200900030000', nameAr: 'النيابة الإلكترونية', nameEn: 'Electronic prosecution', deptName: 'وزارة العدل', description: 'يجوز لأي شخص طبيعي أو معنوي ( الإدارات و المؤسسات،  الشركات الخاصة  و الجمعيات,....)  تقديم الشكاوى أو العرائض أمام  النيابة عن بعد .'),
  '000000200900040000': ServiceCatalogEntry(unid: '000000200900040000', nameAr: 'رخصة الإتصال بمحبوس', nameEn: 'License to communicate with detainees', deptName: 'وزارة العدل', description: ''),
  '000000201200010000': ServiceCatalogEntry(unid: '000000201200010000', nameAr: 'طلب موعد فحص طبي متخصص', nameEn: 'Appointment Request for Specialized Consultation', deptName: 'وزارة الصحة', description: 'إنها خدمة طلب موعد عبر الإنترنت للمواطنين المرفقين  برسالة توجيه طبية، لتمكينهم من الاستفادة من فحوصات طبية متخصصة في مؤسسات الصحة العمومية.'),
  '000000200301040000': ServiceCatalogEntry(unid: '000000200301040000', nameAr: 'نسخة من عقد الملكية', nameEn: 'Copy of the property contract', deptName: 'المديرية العامة للأملاك الوطنية', description: ''),
  '000000200100040000': ServiceCatalogEntry(unid: '000000200100040000', nameAr: 'وثيقة الإقامة ( شهادة  / بطاقة )', nameEn: 'Residence document (Residence Certificate/card)', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: 'إن خدمة طلب وثائق الإقامة (شهادة أو بطاقة) هي إجراء إداري يهدف إلى توفير إثبات رسمي لمكان إقامة المواطن الجزائري. يتم إصدار وثائق الإقامة (شهادة أو بطاقة) لطالبها من طرف البلدية المختصة لتمكينه من استخدامها في مختلف الإجراءات الإدارية (وثائق الهوية، التسجيل في المدارس، طلب السكن...) وهذا مع مراعاة الأحكام التشريعية والتنظيمية المتعلقة بالخدمة المطلوبة.'),
  '000000200100060000': ServiceCatalogEntry(unid: '000000200100060000', nameAr: 'بطاقة ترقيم المركبات', nameEn: 'Vehicle registration card', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: 'تسمح خدمة طلب بطاقة ترقيم المركبة بتقديم طلب الكتروني للحصول على  وثيقة رسمية  تدعى  بطاقة ترقيم المركبة, تحدد هوية المركبة  و  تسمح بوضعها في السير. تحتوي هذه الوثيقة على معلومات أساسية مثل رقم التسجيل والخصائص التقنية للمركبة وكذا هوية المالك. تُعد بطاقة الترقيم  إجبارية لجميع المركبات والمقطورات ونصف المقطورات ويجب تقديمها عند المعاينات المرورية أو عند نقل ملكية المركبة.'),
  '000000201100010000': ServiceCatalogEntry(unid: '000000201100010000', nameAr: 'طلب التسجيل في السنة الأولى ابتدائي', nameEn: 'Application for registration in the first year of primary school', deptName: 'وزارة التربية الوطنية', description: 'تتيح لكم هذه الخدمة تسجيل أبنائكم الذين بلغوا السن القانوني للتمدرس في السنة الأولى ابتدائي، عبر إجراءات وخطوات واضحة وبسيطة. وذلك من أجل تحسين الخدمة العمومية وتخفيف الإجراءات الإدارية على المواطنين.'),
  '000000200500010001': ServiceCatalogEntry(unid: '000000200500010001', nameAr: 'بطاقة الشخص ذي الاحتياجات الخاصة', nameEn: 'Card for the person with special needs', deptName: 'وزارة التضامن الوطني والأسرة وقضايا المرأة', description: 'بطاقة الشخص ذي الاحتياجات الخاصة هي وثيقة تبين طبيعة الإعاقة ودرجتها وتتيح للأشخاص الحصول على الخدمات التي ينص عليها القانون.(بموجب القانون رقم 25-01 المؤرخ 20 فبراير 2025 المتعلق بحماية ورعاية الأشخاص ذوي الاحتياجات الخاصة)'),
  '000000200500010002': ServiceCatalogEntry(unid: '000000200500010002', nameAr: 'تعديل بطاقة الشخص ذي الاحتياجات الخاصة', nameEn: 'Modify the card for person with special needs', deptName: 'وزارة التضامن الوطني والأسرة وقضايا المرأة', description: 'تعديل بطاقة الأشخاص ذوي الاحتياجات الخاصة يتضمن تحديث المعلومات المتعلقة بطبيعة ودرجة الإعاقة، تحديث معلومات الإقامة، أو تحديث معلومات العمر (بالغ 18 سنة او اكثر).(بموجب القانون رقم 25-01 المؤرخ 20 فبراير 2025 المتعلق بحماية ورعاية الأشخاص ذوي الاحتياجات الخاصة)'),
  '000000200301020000': ServiceCatalogEntry(unid: '000000200301020000', nameAr: 'مستخرج حالة قسمCC12', nameEn: 'CC12', deptName: 'المديرية العامة للأملاك الوطنية', description: 'مستخرج حالة القسم هو بيان المعلومات العقارية في حالة طلب قطعة واحدة أو قطعة أرض واحدة'),
  '000000200500020001': ServiceCatalogEntry(unid: '000000200500020001', nameAr: 'المنحة الجزافية للتضامن', nameEn: 'Solidarity Forfaitary Allowance', deptName: 'وزارة التضامن الوطني والأسرة وقضايا المرأة', description: ''),
  '000000200301010000': ServiceCatalogEntry(unid: '000000200301010000', nameAr: 'دفتر عقاري', nameEn: 'Property Register', deptName: 'المديرية العامة للأملاك الوطنية', description: 'الدفتر العقاري وثيقة تتحتوي على معلومات تتعلق بالممتلكات المسجلة بما في ذلك الموقع، المالك، وتاريخ الممتلكات منذ إنشاء هذه الوثيقة. يتم تسليمها للمالك مرة واحدة فقط ليحتفظ بها ويستخدمها عند الحاجة.'),
  '000000200500020002': ServiceCatalogEntry(unid: '000000200500020002', nameAr: 'تعديل بطاقة المنحة الجزافية للتضامن', nameEn: 'Modify the solidarity forfaitary allowance card', deptName: 'وزارة التضامن الوطني والأسرة وقضايا المرأة', description: 'تعديل بطاقة المنحة الجزافية للتضامن يتضمن تحديث معلومات الإقامة'),
  '000000200100070000': ServiceCatalogEntry(unid: '000000200100070000', nameAr: 'الحصول على الهوية الرقمية', nameEn: 'Obtaining a digital identity', deptName: 'وزارة الداخلية والجماعات المحلية و النقل', description: ''),
  '000000200400010000': ServiceCatalogEntry(unid: '000000200400010000', nameAr: 'رخصة البناء الالكترونية', nameEn: 'E-permis of construction', deptName: 'وزارة الداخلية والجماعات المحلية والتهيئة الإقليمية/ وزارة السكن والعمران والمدينة', description: 'رخصة البناء هي عقد إداري، تندرج ضمن عقود  التعمير، تسمح لمصلحة التعمير للبلدية بالمراقبة القبلية لمطابقة مشروع البناء لقواعد التعمير ومعايير السلامة .'),
  '000000201400010000': ServiceCatalogEntry(unid: '000000201400010000', nameAr: 'الربط بشبكة الماء الشروب', nameEn: 'Connection to the drinking water network', deptName: 'وزارة الري', description: 'خدمة الربط بشبكة الماء الشروب هي عملية إلزامية لتزويد المستخدمين بالمياه ، مـــرســوم تـــنــفـــيــذيّ رقم 08 54- مــؤرخ في 2 صـــفـــر عــام  1429 المــــوافق 9 فـــــبــــرايـــــر ســــنــــة 2008 يــــتـــــضــــمن المصادقــة على دفـتر الشروط  النموذجي للتسيير بـــالامــتــيــاز لـــلــخــدمـــة الـــعــمــومـــيــة لــلــتـــزويــد بــالمــاء الشروب و نظام الخدمة المتعلق به.'),
  '000000201400020000': ServiceCatalogEntry(unid: '000000201400020000', nameAr: 'الربط  بشبكة التطهير العمومية', nameEn: 'Connection to the sewage network', deptName: 'وزارة الري', description: ''),
  '000000200301050000': ServiceCatalogEntry(unid: '000000200301050000', nameAr: 'طلب معلومات (موجزة )', nameEn: 'Information requisition (summary)', deptName: 'المديرية العامة للأملاك الوطنية', description: 'يتم إصدار وثيقة طلب المعلومات (الملخص) من قبل المحافظة العقارية، والتي تحدد أصول الخاصة بالمالك (خارج الاجراء) أو حالة العقار العقاري (على الاجراء).'),
  '000000200500020003': ServiceCatalogEntry(unid: '000000200500020003', nameAr: 'إعادة الإصدار في حالة فقدان أو تلف بطاقة المنحة الجزافية للتضامن', nameEn: 'Reissue in case of loss or damage of the solidarity forfaitary allowance card', deptName: 'وزارة التضامن الوطني والأسرة وقضايا المرأة', description: ''),
  '000000201100020000': ServiceCatalogEntry(unid: '000000201100020000', nameAr: 'فضاء الأولياء', nameEn: 'Parents Portal', deptName: 'وزارة التربية الوطنية', description: 'فضاء رقمي موحد تابع لقطاع التربية الوطنية، يتيح لأولياء التلاميذ الولوج عن بُعد إلى مجموعة من الخدمات الرقمية المتعلقة بالمسار الدراسي لأبنائهم، ومتابعة مختلف الإجراءات والعمليات المدرسية، وذلك عبر حساب موحد.\nويتيح فضاء الأولياء الاستفادة من أربعة عشر (14) خدمة رقمية.\nتُتاح الخدمات وفق طبيعة كل خدمة والرزنامة المعتمدة خلال السنة الدراسية، بما يضمن للأولياء سهولة الولوج إلى الخدمات الرقمية ومتابعة وضعية أبنائهم والاستفادة من الإجراءات المتاحة عن بُعد.'),
  '000000201501010000': ServiceCatalogEntry(unid: '000000201501010000', nameAr: 'إسند CREG', nameEn: 'CREG E-SANED', deptName: 'لجنة ضبط الكهرباء و الغاز', description: 'E-saned منصة رقمية مخصصة لمعالجة طلبات منح تراخيص الاستغلال، وكذا التصريحات المتعلقة بمنشآت إنتاج الكهرباء. يوفر هذا النظام الآمن وسهل الاستخدام متابعة أفضل للملفات عبر الإنترنت وتحسين آجالالمعالجة.'),
  '000000201501020000': ServiceCatalogEntry(unid: '000000201501020000', nameAr: 'محاكاة فاتورتي CREG', nameEn: 'CREG Mouhakat Fatourati', deptName: 'لجنة ضبط الكهرباء و الغاز', description: 'تمكن الخدمة الرقمية محاكاة فاتورتي المواطنين، من خواص ومحترفين، من إجراء محاكاة لفاتورة الكهرباء والغاز حسب بيانات الاستهلاك التي يقومون بإدخالها، مما يسهل فهم وتوقع المصاريف. تُعطى الفاتورة الناتجة على سبيل الاسترشاد فقط.'),
  '000000201502010000': ServiceCatalogEntry(unid: '000000201502010000', nameAr: 'الدفع الإلكتروني SONELGAZ', nameEn: 'SONELGAZ e-Payement', deptName: 'وزارة الطاقة و الطاقات المتجددة', description: 'تُعدّ خدمة الدفع الإلكتروني حلاً رقمياً مؤمّناً يتيح للزبائن تسديد فواتير الطاقة الخاصة بالتوتر المنخفض  والضغط المنخفض عبر الإنترنت في أي وقت، باستخدام البطاقة البنكية أو البطاقة الذهبية. وتوفر هذه الخدمة وسيلة دفع بسيطة وسريعة وملائمة، بما يساهم في تحسين تجربة الزبون، وتعزيز جودة الخدمات المقدّمة.'),
  '000000200000010000': ServiceCatalogEntry(unid: '000000200000010000', nameAr: 'أبوستيل', nameEn: 'APOSTILLE', deptName: 'وزارة الشؤون الخارجية والجالية الوطنية بالخارج والشؤون الإفريقية', description: 'الأبوستيل هو تصديق رسمي تصدره السلطات المختصة المعينة من قبل الجزائر. ويُثبت صحة التوقيع، وصفة الشخص الذي وقّع الوثيقة، وكذلك صحة الختم أو الطابع الرسمي الموضوع على الوثيقة العمومية. ويُعترف به في أكثر من 125 دولة طرف في اتفاقية لاهاي المؤرخة في 5 أكتوبر 1961.'),
  '000000200500010003': ServiceCatalogEntry(unid: '000000200500010003', nameAr: 'اعادة إصدار بطاقة الشخص ذي الاحتياجات الخاصة', nameEn: 'Reissuing the card for person with special needs', deptName: 'وزارة التضامن الوطني والأسرة وقضايا المرأة', description: 'اعادة إصدار بطاقة الأشخاص ذوي الاحتياجات الخاصة تتضمن إصدار بطاقة جديدة بدلاً من القديمة. قد يكون ذلك ضروريًا في حالة فقدان البطاقة أو سرقتها أو تلفها. (بموجب القانون رقم 25-01 المؤرخ 20 فبراير 2025 المتعلق بحماية ورعاية الأشخاص ذوي الاحتياجات الخاصة)'),
  '000000201502020000': ServiceCatalogEntry(unid: '000000201502020000', nameAr: 'إطاقتي SONELGAZ', nameEn: 'SONELGAZ e-Taqaty', deptName: 'وزارة الطاقة و الطاقات المتجددة', description: 'e-طاقتي\n \nهي منصة رقمية مؤمّنة تسمح الولوج السلس إلى خدمات الزبائن لسونلغاز. حيث تتيح للمستخدمين الاطلاع على معلوماتهم، متابعة طلباتهم، وإنجاز مختلف الإجراءات عن بُعد، في أي وقت ومن أي مكان، بما يوفر تجربة زبون أكثر سهولة وسرعة وراحة.\nوتهدف المنصة إلى تحسين تجربة الزبون من خلال توفير مسار رقمي بسيط وسلس وسهل الاستخدام، مع تعزيز جودة الخدمات ورفع مستوى كفائتها'),
  '000000201501030000': ServiceCatalogEntry(unid: '000000201501030000', nameAr: 'إلتماس CREG', nameEn: 'CREG ILTIMESS', deptName: 'لجنة ضبط الكهرباء و الغاز', description: 'ILTIMESS منصة رقمية مخصصة لمعالجة طعون المواطنين المقدمة إلى لجنة ضبط الكهرباء والغاز (CREG). وتتيح المنصة، بفضل واجهتها الآمنة وسهلة الاستخدام، للمستهلكين والمستهلكين المستقبليين، سواء كانوا أفراداً أو شركات، إمكانية تتبع حالة ملفاتهم عبر الإنترنت، مما يساهم في تقليص مدة المعالجة.'),
  '000000201503010000': ServiceCatalogEntry(unid: '000000201503010000', nameAr: 'إترشيد', nameEn: 'eTarcheed', deptName: 'الوكالة الوطنية لتطوير إستخدام الطاقة و ترشيده', description: 'البرنامج الوطني لإدارة الطاقة، المعروف باسم   PNME   هو عبارة عن برنامج مدته خمس سنوات لتنفيذ \nالاستراتيجية الوطنية لإدارة الطاقة. \nوهو يتضمن جميع التدابير والإجراءات والمشاريع الخاصة بكفاءة الطاقة ومكافحة هدر الطاقة، المخطط لها خلال الفترة \nالمعنية للقطاعات ذات الإمكانات الأكبر لتوفير الطاقة، مثل تشييد وتجديد المباني والصناعة وقطاع النقل والقطاع العام، \nوخاصة الجماعات المحلية، وبدرجة أقل القطاع الزراعي، الذي تسارعت فيه ديناميكية النمو بشكل واضح في السنوات'),
  '000000201601010000': ServiceCatalogEntry(unid: '000000201601010000', nameAr: 'الخدمات الرقمية للحج', nameEn: 'Digital Hadj Services', deptName: 'الديوان الوطني للحج و العمرة', description: 'البوابة الجزائرية للحج\nمنصة إلكترونية طوّرها الديوان الوطني للحج والعمرة لتسهيل وتنظيم جميع الإجراءات المتعلقة بأداء فريضة الحج للمواطنين الجزائريين.\nتهدف البوابة إلى رقمنة وتبسيط الخدمات المقدمة للحجاج، حيث تتيح لهم إنجاز مختلف الإجراءات عن بُعد، بما في ذلك:\n\nالتسجيل وإنشاء حساب إلكتروني.\n\nحجز تذاكر السفر.\n\nحجز الفنادق والغرف في مكة المكرمة.\n\nاستصدار التأشيرة الإلكترونية.\n\nمتابعة مسار الحاج وطباعة الوثائق اللازمة.'),
  '000000201700010000': ServiceCatalogEntry(unid: '000000201700010000', nameAr: 'بوابة الخدمات العمومية لوزارة الأشغال العمومية والمنشآت القاعدية', nameEn: 'Public Services Portal of the Ministry of Public Works and Basic Infrastructure', deptName: 'وزارة الأشغال العمومية والمنشآت القاعدية', description: 'بوابة الخدمات العمومية لوزارة الأشغال العمومية والمنشآت القاعدية هي منصة رقمية رسمية تتيح للمتعاملين الاقتصاديين والمهندسين ومكاتب الدراسات التقنية الخاصة وكافة المواطنين الاستفادة من مجموعة من الخدمات الإدارية الإلكترونية، وذلك في إطار عصرنة الإدارة العمومية وتبسيط الإجراءات الإدارية وتحسين جودة الخدمة العمومية.\nوتوفر البوابة حالياً الخدمات الإلكترونية التالية:\n1.	شهادة التأهيل والتصنيف المهنيين\n2.	شهادة اعتماد المهندسين ومكاتب الدراسات التقنية الخاصة\n3.	تسليم وثيقة إدارية لتحديد المسافة'),
  '000000201400030000': ServiceCatalogEntry(unid: '000000201400030000', nameAr: 'البوابة الإلكترونية لشهادات التأهيل و التصنيف المهنيين', nameEn: 'The Professional Qualification And Classification portal Hydro-Qualif', deptName: 'وزارة الري', description: 'توفر المنصة خدمات إلكترونية لإيداع وإدارة ومتابعة طلبات شهادات التأهيل والتصنيف المهني الخاصة بالمؤسسات الناشطة في قطاع الموارد المائية. وتمكّن طالبي الخدمة من تقديم الطلبات، وإرفاق الوثائق والمستندات المطلوبة، وتحيين معلومات المؤسسة، ومتابعة حالة الطلب إلى غاية إصدار الشهادات'),
  '000000201900010000': ServiceCatalogEntry(unid: '000000201900010000', nameAr: 'تسجيل طالبي التكوين', nameEn: 'Registration For Vocational Training Applicants', deptName: 'وزارة التكوين والتعليم المهنيين', description: 'منصة تكوين هي إحدى الخدمات الرقمية التي تقدمها وزارة التكوين والتعليم المهنيين، وتهدف إلى تسهيل عملية تسجيل طالبي التكوين. تُمكّن المنصة المتكوّن من إنشاء حساب شخصي يتيح له متابعة مساره التكويني والمهني بشكل مستمر إلى غاية الحصول على الشهادة النهائية.\n- التسجيل المباشر دون الحاجة إلى التنقل إلى مؤسسة التكوين.\n- حساب شخصي يتيح لك متابعة مسارك التكويني حتى التخرج.\n- فضاء رقمي مخصص للمتكوّنين، والمكوّنين، وموظفي القطاع.'),
  '000000202000010000': ServiceCatalogEntry(unid: '000000202000010000', nameAr: 'وظيفتي', nameEn: 'Wadhifati', deptName: 'وزارة الرياضة', description: 'وظيفتي خدمة رقمية تابعة لوزارة الرياضة، تهدف إلى رقمنة وتبسيط إجراءات التوظيف والالتحاق بالتكوين المتخصص في مؤسسات ومدارس التكوين التابعة للقطاع. وتمكّن المترشحين من الاطلاع على عروض التوظيف ومسابقات الالتحاق بالتكوين المتخصص، والتسجيل وإيداع ملفات الترشح، ومتابعة وضعية طلباتهم، واستلام الاستدعاءات والاطلاع على النتائج عن بُعد.'),
  '000000201601040000': ServiceCatalogEntry(unid: '000000201601040000', nameAr: 'الخدمة الإلكترونية لإدارة المسابقات القرآنية الوطنية', nameEn: 'Electronic Service for Managing National Qur’anic Competitions', deptName: 'وزارة الشؤون الدينية والأوقاف', description: 'منصة إلكترونية لإدارة المسابقات القرآنية الوطنية، تتيح للمستخدمين تسجيل المشاركة، ومتابعة ملفات الترشح، وإدارة مختلف مراحل المسابقة، وتقييم المشاركين من طرف لجان التحكيم، والاطلاع على النتائج'),
  '000000202100010000': ServiceCatalogEntry(unid: '000000202100010000', nameAr: 'انخراطي', nameEn: 'YouthConnect', deptName: 'وزارة الشباب', description: 'منصة رقمية موحدة للمؤسسات الشبابية تهدف إلى تعزيز جاذبيتها وتحسين تسييرها، من خلال تمكين الشباب من الاطلاع على برامج وأنشطة المؤسسات، والانخراط فيها، والمشاركة في مختلف الأنشطة، إضافة إلى توفير خريطة رقمية للمؤسسات الشبابية، بما يساهم في متابعة الخدمات والأنشطة وتوفير معطيات دقيقة لدعم اتخاذ القرار'),
  '000000202100020000': ServiceCatalogEntry(unid: '000000202100020000', nameAr: 'شراكة', nameEn: 'Charaka', deptName: 'وزارة الشباب', description: 'منصة رقمية مخصصة للجمعيات الشبابية، تهدف إلى دعم دورها كشريك أساسي في تنفيذ سياسات قطاع الشباب، من خلال تمكين الجمعيات من التسجيل الرقمي، والمشاركة في دعوات تمويل المشاريع الجمعوية، وتسهيل التنسيق ومتابعة البرامج والمبادرات والمشاريع الموجهة للشباب.'),
  '000000202100030000': ServiceCatalogEntry(unid: '000000202100030000', nameAr: 'مخيمي', nameEn: 'YouthCamp', deptName: 'وزارة الشباب', description: 'منصة رقمية مخصصة لتسيير وتنظيم برامج مراكز العطل والترفيه للشباب، تهدف إلى تحسين الحوكمة وتبسيط الإجراءات من خلال تمكين الشباب من التسجيل للاستفادة من البرامج، وتسهيل طلبات اعتماد التأطير، ومتابعة المستفيدين، وتعزيز التنسيق بين مختلف المتدخلين في تنظيم المخيمات.'),
  '000000202100040000': ServiceCatalogEntry(unid: '000000202100040000', nameAr: 'تكوين', nameEn: 'Takwin', deptName: 'وزارة الشباب', description: 'منصة رقمية مخصصة لتسيير ومتابعة عمليات التوظيف والتكوين على مستوى مؤسسات ومعاهد التكوين التابعة لقطاع الشباب، تتيح التسجيل والترشح في مسابقات التوظيف، وتساهم في تحسين متابعة برامج التكوين وتسيير معاهد القطاع، بما يعزز نجاعة وشفافية العمليات الإدارية والتكوينية.'),
  '000000202100050000': ServiceCatalogEntry(unid: '000000202100050000', nameAr: 'مهرجاني', nameEn: 'Festival', deptName: 'وزارة الشباب', description: 'منصة رقمية موحدة لتسيير المهرجانات والتظاهرات الشبابية المنظمة من طرف قطاع الشباب، تتيح للشباب التسجيل والمشاركة في مختلف المهرجانات، وتساهم في برمجة ومتابعة وتقييم هذه التظاهرات، بما يعزز حوكمتها ويرفع من فعالية تنظيمها.'),
  '000000202100060000': ServiceCatalogEntry(unid: '000000202100060000', nameAr: 'القادة الشباب', nameEn: 'YoungLeaders', deptName: 'وزارة الشباب', description: 'منصة رقمية مخصصة لبرنامج القادة الشباب، تهدف إلى اكتشاف وتأهيل ومرافقة الشباب ذوي المبادرات والقدرات القيادية، من خلال تمكينهم من التسجيل والمشاركة في البرنامج، وتسهيل عملية اختيارهم ومتابعة مسارهم، بما يعزز مشاركتهم في التنمية وترسيخ قيم المواطنة الفاعلة.'),
  '000000202100070000': ServiceCatalogEntry(unid: '000000202100070000', nameAr: 'حركية', nameEn: 'YouthHouse', deptName: 'وزارة الشباب', description: 'منصة رقمية مخصصة لتسيير برامج الحركية الموجهة للشباب، تتيح التسجيل والاستفادة من مختلف برامج الحركية، وتساهم في تنظيم ومتابعة المستفيدين والعمليات المرتبطة بها، بما يعزز فرص التنقل والتبادل والانفتاح على مختلف التجارب والبرامج الموجهة للشباب.'),
  '000000201601050000': ServiceCatalogEntry(unid: '000000201601050000', nameAr: 'مقرأة إلكترونية', nameEn: 'Electronic Maqraa', deptName: 'وزارة الشؤون الدينية والأوقاف', description: 'منصة إلكترونية لإدارة المسابقات القرآنية الوطنية، تتيح للمستخدمين تسجيل المشاركة، ومتابعة ملفات الترشح، وإدارة مختلف مراحل المسابقة، وتقييم المشاركين من طرف لجان التحكيم، والاطلاع على النتائج.'),
  '000000201601020000': ServiceCatalogEntry(unid: '000000201601020000', nameAr: 'البوابة الجزائرية للعمرة', nameEn: 'Bawabatelomra', deptName: 'الديوان الوطني للحج و العمرة', description: ''),
};

/// Pre-application guide questions per service (unid -> questions).
/// Services that redirect to an external portal have no entry here.
const Map<String, List<ServiceGuideQuestion>> serviceGuides = {
  '000000200100010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('ما هي علاقتك بصاحب الشهادة؟', true, [ServiceGuideAnswer('نفسي', 'certificate_holder_rela_birth-1'), ServiceGuideAnswer('الوالدين', 'certificate_holder_rela_birth-2'), ServiceGuideAnswer('الأولاد', 'certificate_holder_rela_birth-3'), ServiceGuideAnswer('الزوج/الزوجة', 'certificate_holder_rela_birth-4'), ServiceGuideAnswer('الوصي', 'certificate_holder_rela_birth-5')]),
  ],
  '000000200100020000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('ما هي علاقتك بصاحب الشهادة؟', true, [ServiceGuideAnswer('نفسي', 'certificate_holder_rela_marriage-1'), ServiceGuideAnswer('الوالدين', 'certificate_holder_rela_marriage-2'), ServiceGuideAnswer('الأولاد', 'certificate_holder_rela_marriage-3')]),
  ],
  '000000200100030000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('ما هي علاقتك بصاحب الشهادة؟', true, [ServiceGuideAnswer('الأولاد', 'certificate_holder_rela_death-1'), ServiceGuideAnswer('الوالدين', 'certificate_holder_rela_death-2'), ServiceGuideAnswer('الزوج/الزوجة', 'certificate_holder_rela_death-3')]),
  ],
  '000000200203010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('يرجى تأكيد معلومات جنسيتك؟', true, [ServiceGuideAnswer('الجنسية الجزائرية المولودة في الجزائر', 'your_nationality_information-01'), ServiceGuideAnswer('الجنسية الجزائرية المولودة خارج الجزائر', 'your_nationality_information-02')]),
    ServiceGuideQuestion('هل أنت منتسب أو منتسب مسبقاً ؟', true, [ServiceGuideAnswer('لا', 'are_you_affiliated-0'), ServiceGuideAnswer('نعم', 'are_you_affiliated-1')]),
  ],
  '000000200201010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('المهنة؟', true, [ServiceGuideAnswer('التجارة', 'occupation_type-1'), ServiceGuideAnswer('الحرف اليدوية', 'occupation_type-2'), ServiceGuideAnswer('الفلاحة', 'occupation_type-3'), ServiceGuideAnswer('المقاولة الذاتية', 'occupation_type-4'), ServiceGuideAnswer('المهن الحرة', 'occupation_type-5'), ServiceGuideAnswer('النقل', 'occupation_type-6'), ServiceGuideAnswer('الصيد البحري', 'occupation_type-7')]),
  ],
  '000000200201020000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200204020000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200204010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200301030000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('هل أنت مالك هذا العقار ؟', true, [ServiceGuideAnswer('لا', 'owner_of_the_property-0'), ServiceGuideAnswer('نعم', 'owner_of_the_property-1')]),
    ServiceGuideQuestion('هل تتقدم بالطلب لفائدة؟', true, [ServiceGuideAnswer('شخص طبيعي', 'person_type_applying_for-natural_person'), ServiceGuideAnswer('شخص اعتباري', 'person_type_applying_for-moral_person')]),
    ServiceGuideQuestion('نوع الطلب', true, [ServiceGuideAnswer('الأبجدية', 'what_type_want_apply_for-01'), ServiceGuideAnswer('البطاقة الشخصية', 'what_type_want_apply_for-02'), ServiceGuideAnswer('البطاقة الخاصة الحضرية', 'what_type_want_apply_for-03'), ServiceGuideAnswer('بطاقة قطع الاراضي', 'what_type_want_apply_for-04')]),
  ],
  '000000200202010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200302010000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('أنتم ؟', true, [ServiceGuideAnswer('شخص طبيعي', 'you_are-1'), ServiceGuideAnswer('  شخص معنوي  ', 'you_are-2')]),
    ServiceGuideQuestion('الرجاء اختيار مجال النشاط ؟', true, [ServiceGuideAnswer('النشاط التجاري', 'citizen_activity_domain_DGI-1'), ServiceGuideAnswer('النشاط الحر', 'citizen_activity_domain_DGI-2'), ServiceGuideAnswer('خارج النشاط', 'citizen_activity_domain_DGI-3')]),
    ServiceGuideQuestion('الرجاء اختيار مجال النشاط ؟', true, [ServiceGuideAnswer('الاشخاص المعنويين الخاضعين للقانون الجزائري', 'legal_activity_domain_DGI-1'), ServiceGuideAnswer('الاشخاص المعنويين الخاضعين للقانون الأجنبي', 'legal_activity_domain_DGI-2'), ServiceGuideAnswer('الهيئات الادارية', 'legal_activity_domain_DGI-3'), ServiceGuideAnswer('الشركات المدنية', 'legal_activity_domain_DGI-4'), ServiceGuideAnswer('الجمعيات المعتمدة', 'legal_activity_domain_DGI-5'), ServiceGuideAnswer('تجمعات ذات مصالح مشتركة والهيئات المهنية المشتركة', 'legal_activity_domain_DGI-6'), ServiceGuideAnswer('مكتب التنسيق', 'legal_activity_domain_DGI-7'), ServiceGuideAnswer('المنظمات المهنية و المهنية المشتركة في مجال الزراعة,الصيد أو الحرف', 'legal_activity_domain_DGI-8'), ServiceGuideAnswer('التمثيليات  الدبلوماسية والقنصلية والهيئات المنشأة بموجب الاتفاقيات الدولية', 'legal_activity_domain_DGI-9')]),
  ],
  '000000200302030000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('هل انتم ؟', true, [ServiceGuideAnswer('شخص طبيعي', 'you_are_c20-1'), ServiceGuideAnswer('شخص معنوي', 'you_are_c20-2')]),
    ServiceGuideQuestion('Hide Trigger', false, [ServiceGuideAnswer('نعم', 'hide_trigger-Y'), ServiceGuideAnswer('لا', 'hide_trigger-N')]),
    ServiceGuideQuestion('الرجاء اختيار مجال النشاط', true, [ServiceGuideAnswer('النشاط التجاري', 'citizen_activity_domain_DGI-1'), ServiceGuideAnswer('النشاط الحر', 'citizen_activity_domain_DGI-2'), ServiceGuideAnswer('خارج النشاط', 'citizen_activity_domain_DGI-3'), ServiceGuideAnswer('نشاط ممارس في إطار القانون الأساسي للمقاول الذاتي', 'citizen_activity_domain_DGI-4'), ServiceGuideAnswer('نشاط فلاحي', 'citizen_activity_domain_DGI-5'), ServiceGuideAnswer('نشاط حرفي', 'citizen_activity_domain_DGI-6')]),
    ServiceGuideQuestion('?الرجاء اختيار مجال النشاط', true, [ServiceGuideAnswer('الاشخاص المعنويين الخاضعين للقانون الجزائري', 'legal_activity_domain_DGI-1'), ServiceGuideAnswer('الاشخاص المعنويين الخاضعين للقانون الأجنبي', 'legal_activity_domain_DGI-2'), ServiceGuideAnswer('الهيئات الادارية', 'legal_activity_domain_DGI-3'), ServiceGuideAnswer('الشركات المدنية', 'legal_activity_domain_DGI-4'), ServiceGuideAnswer('الجمعيات المعتمدة', 'legal_activity_domain_DGI-5'), ServiceGuideAnswer('تجمعات ذات مصالح مشتركة والهيئات المهنية المشتركة', 'legal_activity_domain_DGI-6'), ServiceGuideAnswer('مكتب التنسيق', 'legal_activity_domain_DGI-7'), ServiceGuideAnswer('المنظمات المهنية و المهنية المشتركة في مجال الزراعة,الصيد أو الحرف', 'legal_activity_domain_DGI-8'), ServiceGuideAnswer('التمثيليات  الدبلوماسية والقنصلية والهيئات المنشأة بموجب الاتفاقيات الدولية', 'legal_activity_domain_DGI-9')]),
  ],
  '000000200302040000': [
    ServiceGuideQuestion('وصف الخدمة', false, []),
    ServiceGuideQuestion('مكان الازدياد؟', true, [ServiceGuideAnswer('خارج الجزائر', 'you_birth_place-1'), ServiceGuideAnswer('في الجزائر', 'you_birth_place-2')]),
    ServiceGuideQuestion('الرجاء اختيار مجال النشاط', true, [ServiceGuideAnswer('النشاط التجاري', 'citizen_activity_domain_DGI-1'), ServiceGuideAnswer('النشاط الحر', 'citizen_activity_domain_DGI-2'), ServiceGuideAnswer('خارج النشاط', 'citizen_activity_domain_DGI-3')]),
  ],
  '000000200700010001': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('حالة مقدم الطلب؟', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ما هو نوع الطلب؟', true, [ServiceGuideAnswer('طلب تسجيل جديد', 'applicant_type_farmer_card-1'), ServiceGuideAnswer('طلب التحويل', 'applicant_type_farmer_card-2'), ServiceGuideAnswer('طلب إعادة الإدماج', 'applicant_type_farmer_card-3')]),
    ServiceGuideQuestion('هل لديك قطعة أرض ؟', true, [ServiceGuideAnswer('نعم', 'plot_existance-Y'), ServiceGuideAnswer('لا', 'plot_existance-N')]),
  ],
  '000000200302050000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('الرجاء اختيار المشهد الخاص بك ؟', true, [ServiceGuideAnswer('أشخاص معنويون خاضعون للقانون الجزائري (مسجلون في المركز الوطني للسجل التجاري)', 'please_choose_scene-1'), ServiceGuideAnswer('المؤسسات الأجنبية التي ليست لها إقامة مهنية دائمة بالجزائر', 'please_choose_scene-2'), ServiceGuideAnswer('الهيئات الادارية ', 'please_choose_scene-3'), ServiceGuideAnswer('الشركات المدنية', 'please_choose_scene-4'), ServiceGuideAnswer(' الجمعيات المعتمدة والتجمعات ذات المصالح المشتركة والهيئات المهنية المشتركة ', 'please_choose_scene-5'), ServiceGuideAnswer('مكاتب الربط للشركات الأجنبية', 'please_choose_scene-6'), ServiceGuideAnswer('المنظمات المهنية و المهنية المشتركة في مجال الزراعة,الصيد أو الحرف ', 'please_choose_scene-7'), ServiceGuideAnswer('التمثيليات  الدبلوماسية والقنصلية والهيئات المنشأة بموجب الاتفاقيات الدولية', 'please_choose_scene-8')]),
  ],
  '000000201300010000': [
    ServiceGuideQuestion('ماذا تفعل الخدمة ؟', false, []),
    ServiceGuideQuestion('من فضلك اختر الشهادة محل طلب الإعتراف ؟', true, [ServiceGuideAnswer('شهادة الدكتوراه', 'type_of_your_diploma-1'), ServiceGuideAnswer('شهادة الماستر', 'type_of_your_diploma-2'), ServiceGuideAnswer('شهادة الليسانس', 'type_of_your_diploma-3'), ServiceGuideAnswer('شهادة البكالوريا', 'type_of_your_diploma-4'), ServiceGuideAnswer('شهادة مهندس معماري', 'type_of_your_diploma-5'), ServiceGuideAnswer('شهادة مهندس دولة', 'type_of_your_diploma-6'), ServiceGuideAnswer('شهادة دكتور في الطب البيطري', 'type_of_your_diploma-7'), ServiceGuideAnswer('شهادة دكتور في الصيدلة', 'type_of_your_diploma-8'), ServiceGuideAnswer('شهادة في طب الأسنان', 'type_of_your_diploma-9'), ServiceGuideAnswer('شهادة دكتور في الطب', 'type_of_your_diploma-10'), ServiceGuideAnswer('شهادة الدراسات الطبية الخاصة (DEMS)', 'type_of_your_diploma-11')]),
  ],
  '000000200100050000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200900010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('مولود في الجزائر ؟', true, [ServiceGuideAnswer('لا', 'is_born_in_algeria-0'), ServiceGuideAnswer('نعم', 'is_born_in_algeria-1')]),
  ],
  '000000200204030000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('هل وصلت إلى سن التقاعد القانوني و غير نشط ؟', true, [ServiceGuideAnswer('لا', 'statutory_retire_age_inactive-0'), ServiceGuideAnswer('نعم', 'statutory_retire_age_inactive-1')]),
  ],
  '000000200900020000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200900030000': [
    ServiceGuideQuestion('نوع مقدم الطلب', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('يرجى اختيار الإقامة ؟', true, [ServiceGuideAnswer('داخل الوطن', 'please_select_the_residence-1'), ServiceGuideAnswer('خارج الوطن', 'please_select_the_residence-2')]),
  ],
  '000000200900040000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('الرجاء اختيار العلاقة بين مقدم الطلب والسجين ؟', true, [ServiceGuideAnswer('ذوي المحبوس', 'relationship_applicant_prisoner-1'), ServiceGuideAnswer('محامي', 'relationship_applicant_prisoner-2'), ServiceGuideAnswer('موثق', 'relationship_applicant_prisoner-3'), ServiceGuideAnswer('محضر قضائي', 'relationship_applicant_prisoner-4')]),
  ],
  '000000201200010000': [
    ServiceGuideQuestion('ماذا تقدم الخدمة؟', false, []),
    ServiceGuideQuestion('هل انت هو المعني بالموعد الطبي', true, [ServiceGuideAnswer('نعم', 'one_concerned_by_the_medical-Y'), ServiceGuideAnswer('لا', 'one_concerned_by_the_medical-N')]),
  ],
  '000000200301040000': [
    ServiceGuideQuestion('نوع مقدم الطلب', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع  الطلب', true, [ServiceGuideAnswer('العقود و الاحكام القضائية', 'what_type_apply_for-06'), ServiceGuideAnswer('الرهن و الإمتيازات', 'what_type_apply_for-04'), ServiceGuideAnswer('تجديد الرهن', 'what_type_apply_for-05'), ServiceGuideAnswer('شطب الرهن', 'what_type_apply_for-01'), ServiceGuideAnswer('عريضة', 'what_type_apply_for-02'), ServiceGuideAnswer('حجز', 'what_type_apply_for-03')]),
  ],
  '000000200100040000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('من هو مقدم الطلب؟', true, [ServiceGuideAnswer('المعني شخصيا', 'apply_for_who-1'), ServiceGuideAnswer('ذوي الحقوق (الزوج (ة)، الأبناء، والدي الزوج (ة) الذين يصرحون بالعيش تحت نفس السقف).', 'apply_for_who-2')]),
    ServiceGuideQuestion('ما هي صفة حامل وثيقة إثبات الإقامة؟', true, [ServiceGuideAnswer('مالك السكن', 'status_of_the_holder-1'), ServiceGuideAnswer('مستأجر', 'status_of_the_holder-2'), ServiceGuideAnswer('مستفيد من السكن الوظيفي', 'status_of_the_holder-3')]),
    ServiceGuideQuestion('نوع وثيقة الإقامة (شهادة - بطاقة)', false, [ServiceGuideAnswer('شهادة إقامة', 'type_of_residence_document-1'), ServiceGuideAnswer('بطاقة إقامة', 'type_of_residence_document-2')]),
  ],
  '000000200100060000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', true, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ماهو سيناريو الطلب ؟', true, [ServiceGuideAnswer('طلب بطاقة ترقيم مركبة جديدة مقتناة لدى وكيل أو مصنّع', 'vehicle_registration_card_application_scenario-1'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة جديدة مستوردة من طرف شخص طبيعي أو معنوي لحسابه الخاص', 'vehicle_registration_card_application_scenario-2'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة مستعملة مستوردة من طرف شخص طبيعي أو معنوي لحسابه الخاص', 'vehicle_registration_card_application_scenario-3'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة مستوردة جديدة أو مستعملة تابعة لمتعاونين أجانب متعاقدين', 'vehicle_registration_card_application_scenario-4'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة مباعة فيما بين متعاونين أجانب متعاقدين', 'vehicle_registration_card_application_scenario-5'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة جديدة أو مستعملة مستوردة في إطار الإستيراد المؤقت من طرف الشركات الأجنبية التي تحوز على عقد عمل في الجزائر', 'vehicle_registration_card_application_scenario-6'), ServiceGuideAnswer('طلب بطاقة ترقيم عادية للمركبات التابعة للممثليات الدبلوماسية أو القنصلية  أو لأعوانها أو للمنظمات الدولية أو الجهوية المعتمدة بالجزائر، المقتناة من السوق المحلي لدى وكيل أو مصنع معتمد بالجزائر مع دفع الرسوم والضرائب بما في ذلك ضريبة القيمة المضافة  : (ملف يودع بالبلدية)', 'vehicle_registration_card_application_scenario-7'), ServiceGuideAnswer('طلب بطاقة ترقيم عادية للمركبات التابعة للممثليات الدبلوماسية أو القنصلية  أو لأعوانها أو للمنظمات الدولية أو الجهوية المعتمدة بالجزائر، المقتناة من السوق المحلي لدى شخص طبيعي أو معنوي مع دفع الرسوم والضرائب بما في ذلك ضريبة القيمة المضافة  : (ملف يودع بالبلدية)', 'vehicle_registration_card_application_scenario-8'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة مقتناة من قبل شخص طبيعي أو معنوي لدى الممثليات الدبلوماسية أو القنصلية  أو أعوانها أو المنظمات الدولية أو الجهوية المعتمدة بالجزائر  (ملف يودع بالبلدية)', 'vehicle_registration_card_application_scenario-9'), ServiceGuideAnswer('طلب بطاقة الترقيم في حالة مركبة مباعة بين أشخاص طبيعيين أو معنويين', 'vehicle_registration_card_application_scenario-10'), ServiceGuideAnswer('طلب بطاقة ترقيم معدات الأشغال العمومية الجديدة', 'vehicle_registration_card_application_scenario-11'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة مقتناة لدى مصالح الجمارك أو أملاك الدولة،  في إطار البيع بالمزاد العلني من طرف محافظ البيع بالمزايدة', 'vehicle_registration_card_application_scenario-12'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة تم بيعها بموجب قرار من العدالة من خلال المزاد العلني', 'vehicle_registration_card_application_scenario-13'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة في حالات الضياع، السرقة والتلف', 'vehicle_registration_card_application_scenario-14'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة أدخلت عليها تعديلات بارزة', 'vehicle_registration_card_application_scenario-15'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة في حالة إضافة عبارة غاز البترول المميع GPL/C', 'vehicle_registration_card_application_scenario-16'), ServiceGuideAnswer('طلب بطاقة ترقيم مركبة في حالة تغيير إقامة مالك المركبة', 'vehicle_registration_card_application_scenario-17'), ServiceGuideAnswer('طلب بطاقة ترقيم في حالة وفاة مالك المركبة', 'vehicle_registration_card_application_scenario-18')]),
  ],
  '000000201100010000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('هل الطفل مولود بالجزائر ؟', true, [ServiceGuideAnswer('نعم', 'was_the_child_born_in_algeria-Y'), ServiceGuideAnswer('لا', 'was_the_child_born_in_algeria-N')]),
    ServiceGuideQuestion('نوع المدرسة ؟', true, [ServiceGuideAnswer('عمومية', 'school_type-1'), ServiceGuideAnswer('خاصة', 'school_type-2')]),
    ServiceGuideQuestion('اختيار المدرسة حسب مقر العمل أم مكان الإقامة ؟', true, [ServiceGuideAnswer('مكان الإقامة', 'school_selection_based_on-residence_place'), ServiceGuideAnswer('مكان العمل', 'school_selection_based_on-work_place')]),
  ],
  '000000200500010001': [
    ServiceGuideQuestion('بطاقة الشخص ذي الاحتياجات الخاصة هي وثيقة تبين طبيعة الإعاقة ودرجتها وتتيح للأشخاص الحصول على الخدمات التي ينص عليها القانون.(بموجب القانون رقم 25-01 المؤرخ 20 فبراير 2025 المتعلق بحماية ورعاية الأشخاص ذوي الاحتياجات الخاصة)', false, []),
    ServiceGuideQuestion('ما هي علاقتك بطالب بطاقة الأشخاص ذوي الاحتياجات الخاصة؟', true, [ServiceGuideAnswer('طالب البطاقة نفسه', 'applicant_request_people_card-1'), ServiceGuideAnswer('والدي طالب البطاقة ( الابن أقل من 18 سنة)', 'applicant_request_people_card-2'), ServiceGuideAnswer('احد الأبناء البالغين للسن القانوني للشخص طالب البطاقة', 'applicant_request_people_card-3'), ServiceGuideAnswer('الولي الشرعي (من غيرأحد الوالدين)  لطالب البطاقة ( الابن أقل من 18 سنة)', 'applicant_request_people_card-4'), ServiceGuideAnswer('موكل من قبل  طالب البطاقة  لطلب الخدمة نيابة عنه', 'applicant_request_people_card-5'), ServiceGuideAnswer('موكل من والدي او الولي الشرعي لطالب البطاقة ( الابن أقل من 18 سنة) لطلب الخدمة نيابة عنه', 'applicant_request_people_card-6')]),
    ServiceGuideQuestion('الحالة الاجتماعية لطالب البطاقة ؟', true, [ServiceGuideAnswer('متزوج(ة)', 'family_card_applicant_situation-1'), ServiceGuideAnswer('مطلق(ة)', 'family_card_applicant_situation-2'), ServiceGuideAnswer('أرمل(ة)', 'family_card_applicant_situation-3'), ServiceGuideAnswer('أعزب/عزباء', 'family_card_applicant_situation-4')]),
  ],
  '000000200500010002': [
    ServiceGuideQuestion('تعديل بطاقة الأشخاص ذوي الاحتياجات الخاصة يتضمن تحديث المعلومات المتعلقة بطبيعة ودرجة الإعاقة، تحديث معلومات الإقامة، أو تحديث معلومات العمر (بالغ 18 سنة او اكثر).(بموجب القانون رقم 25-01 المؤرخ 20 فبراير 2025 المتعلق بحماية ورعاية الأشخاص ذوي الاحتياجات الخاصة)', false, []),
    ServiceGuideQuestion('ما هي علاقتك بالشخص ذي الاحتياجات الخاصة؟', true, [ServiceGuideAnswer('المستفيد', 'person_relationship_needs-1'), ServiceGuideAnswer('والدي المستفيد ( الابن أقل من 18 سنة)', 'person_relationship_needs-2'), ServiceGuideAnswer('احد الأبناء البالغين للمستفيد', 'person_relationship_needs-3'), ServiceGuideAnswer('الوصي القانوني (من غيرأحد الوالدين) للمستفيد ( الابن أقل من 18 سنة)', 'person_relationship_needs-4'), ServiceGuideAnswer('موكل من المستفيد لطلب الخدمة بالنيابة عنه', 'person_relationship_needs-5'), ServiceGuideAnswer('موكل من ولي أمر المستفيد ( الابن أقل من 18 سنة) لطلب الخدمة نيابة عنه', 'person_relationship_needs-6')]),
    ServiceGuideQuestion('تحديث معلومات نسبة او طبيعة الاعاقة', true, [ServiceGuideAnswer('لا', 'update_disability_nature_info-0'), ServiceGuideAnswer('نعم', 'update_disability_nature_info-1')]),
    ServiceGuideQuestion('تحديث معلومات الاقامة', true, [ServiceGuideAnswer('لا', 'update_information-0'), ServiceGuideAnswer('نعم', 'update_information-1')]),
    ServiceGuideQuestion('تحديث معلومات العمر(بالغ 18 سنة او اكثر)', true, [ServiceGuideAnswer('لا', 'update_age_information-0'), ServiceGuideAnswer('نعم', 'update_age_information-1')]),
  ],
  '000000200301020000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('؟ CC12 ما هي الطريقة لتقديم طلب', true, [ServiceGuideAnswer('طلب باستخدام معلومات المالك', 'intend_to_apply_for_cc12-1'), ServiceGuideAnswer('طلب باستخدام البيانات الجغرافية', 'intend_to_apply_for_cc12-2'), ServiceGuideAnswer('طلب باستخدام مخطط الموقع', 'intend_to_apply_for_cc12-3')]),
    ServiceGuideQuestion('هل  أنت المالك لهذة القطعة الأرضية ؟', true, [ServiceGuideAnswer('نعم', 'question_owner_land-Y'), ServiceGuideAnswer('لا', 'question_owner_land-N')]),
  ],
  '000000200500020001': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
    ServiceGuideQuestion('يرجى تحديد علاقتك مع المعني', true, [ServiceGuideAnswer('أنا أتقدم بطلب للحصول على المنحة لنفسي', 'relationship_concern_person-1'), ServiceGuideAnswer('والد طالب الاستفادة من المنحة', 'relationship_concern_person-2'), ServiceGuideAnswer('والدة طالب الاستفادة من المنحة', 'relationship_concern_person-3'), ServiceGuideAnswer('فرد من أفراد الأسرة من الأبناء البالغين للشخص المعني بالمنحة', 'relationship_concern_person-4'), ServiceGuideAnswer('الولي الشرعي  لطالب الاستفادة من المنحة', 'relationship_concern_person-5'), ServiceGuideAnswer('زوج(ة) الشخص المعني بالمنحة', 'relationship_concern_person-6')]),
    ServiceGuideQuestion('يرجى تحديد عمر الشخص المعني', true, [ServiceGuideAnswer('السن أقل من 18 سنة', 'age_concerned_person-1'), ServiceGuideAnswer('السن اكبر او يساوي 18 سنة و أقل من 60 سنة', 'age_concerned_person-2'), ServiceGuideAnswer('السن اكبر او يساوي 60 سنة', 'age_concerned_person-3')]),
    ServiceGuideQuestion('يرجى تحديد جنس الشخص المعني', true, [ServiceGuideAnswer('أنثى', 'sex_of_concerned_person-F'), ServiceGuideAnswer('ذكر', 'sex_of_concerned_person-M')]),
    ServiceGuideQuestion('يرجى تحديد الحالة العائلية للشخص المعني', true, [ServiceGuideAnswer('متزوج(ة)', 'concern_person_marriage_status-B1'), ServiceGuideAnswer('مطلق(ة)', 'concern_person_marriage_status-B2'), ServiceGuideAnswer('أرمل(ة)', 'concern_person_marriage_status-B3'), ServiceGuideAnswer('أعزب /عزباء', 'concern_person_marriage_status-B4')]),
    ServiceGuideQuestion('يرجى تحديد حالتك العائلية', true, [ServiceGuideAnswer('متزوج(ة)', 'select_marriage_situation-1'), ServiceGuideAnswer('مطلق(ة)', 'select_marriage_situation-2'), ServiceGuideAnswer('أرمل /أرملة', 'select_marriage_situation-3')]),
    ServiceGuideQuestion('ما هو سبب التقدم بطلبك', true, [ServiceGuideAnswer('من ذوي الاحتياجات الخاصة', 'what_apply_reason-1'), ServiceGuideAnswer('مرض مزمن', 'what_apply_reason-2'), ServiceGuideAnswer('رب(ة) عائلة', 'what_apply_reason-3'), ServiceGuideAnswer('تعيش بمفردك وغير قادر على العمل', 'what_apply_reason-4'), ServiceGuideAnswer('لا تعيش في مؤسسة التضامن الخاصة', 'what_apply_reason-5')]),
  ],
  '000000200301010000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', true, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('طبيعة الملكية', true, [ServiceGuideAnswer('مالك واحد', 'what_is_the_owner_type_natural-1'), ServiceGuideAnswer('عدة ملاك (ملكية مشتركة/ ملكية في الشيوع)', 'what_is_the_owner_type_natural-2'), ServiceGuideAnswer('وراثة', 'what_is_the_owner_type_natural-3')]),
    ServiceGuideQuestion('طبيعة الوراثة', true, [ServiceGuideAnswer('وريث واحد', 'what_is_the_inherit_type-1'), ServiceGuideAnswer('وريثان أو أكثر', 'what_is_the_inherit_type-2')]),
    ServiceGuideQuestion('طبيعة المالك', true, [ServiceGuideAnswer('مالك واحد', 'what_is_the_owner_type_legal-1'), ServiceGuideAnswer('عدة ملاك (ملكية مشتركة/ ملكية في الشيوع)', 'what_is_the_owner_type_legal-2')]),
  ],
  '000000200500020002': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('ما هي علاقتك بالمستفيد؟', true, [ServiceGuideAnswer('المستفيد نفسه', 'beneficiary_relationship-1'), ServiceGuideAnswer('عائلة المستفيد (الوالدين ، الزوج ، الزوجة ، الأبن البالغ)', 'beneficiary_relationship-2'), ServiceGuideAnswer('الوصي القانوني للمستفيد', 'beneficiary_relationship-3')]),
  ],
  '000000200100070000': [
    ServiceGuideQuestion('ماذا تتيح هذه الخدمة ؟', false, []),
  ],
  '000000200400010000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', true, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ماهي طبيعة الطلب ؟', true, [ServiceGuideAnswer('طلب جديد', 'question_nature_application-0'), ServiceGuideAnswer('تعديل', 'question_nature_application-1'), ServiceGuideAnswer('تجديد', 'question_nature_application-2')]),
    ServiceGuideQuestion('يرجى اختيار نوع المشروع ؟', true, [ServiceGuideAnswer('سكن', 'question_type_project-1'), ServiceGuideAnswer('تجهيزات', 'question_type_project-2'), ServiceGuideAnswer('مؤسسة تستقبل الجمهور', 'question_type_project-3')]),
    ServiceGuideQuestion('الرجاء اختيار طبيعة المبنى ؟', true, [ServiceGuideAnswer('فردي', 'question_nature_building-1'), ServiceGuideAnswer('شبه جماعي', 'question_nature_building-2'), ServiceGuideAnswer('جماعي', 'question_nature_building-3')]),
    ServiceGuideQuestion('الرجاء اختيار طبيعة المنشأة  ؟', true, [ServiceGuideAnswer('منشأة انتاج الكهرباء', 'question_nature_infrastructure-0'), ServiceGuideAnswer('منشأة نقل الطاقة الكهربائية', 'question_nature_infrastructure-1'), ServiceGuideAnswer('منشأة توزيع  الطاقة الكهربائية', 'question_nature_infrastructure-2'), ServiceGuideAnswer('منشأة نقل الغاز', 'question_nature_infrastructure-3'), ServiceGuideAnswer('منشأة توزيع  الغاز بواسطة قنوات', 'question_nature_infrastructure-4'), ServiceGuideAnswer('محطة ثابتة لضغط الغاز', 'question_nature_infrastructure-5'), ServiceGuideAnswer('محطة غازالبترول المميع', 'question_nature_infrastructure-6')]),
    ServiceGuideQuestion('الرجاء اختيار طبيعة المنشأة الناقلة للطاقة الكهربائية  ؟', true, [ServiceGuideAnswer('خطوط نقل الكهرباء الهوائية و الأرضية بالجهد العالي', 'nature_infras_ele_power-0'), ServiceGuideAnswer('االمحطات الكهربائية (محطات التحويل و محطات الترابط )', 'nature_infras_ele_power-1')]),
    ServiceGuideQuestion('الرجاء اختيار طبيعة المنشأة الموزعة للطاقة الكهربائية  ؟', true, [ServiceGuideAnswer('الخطوط الكهربائية', 'question_nature_infrastruct_dist-0'), ServiceGuideAnswer('المحطة الكهربائية (المحولات الكهربائية)', 'question_nature_infrastruct_dist-1')]),
    ServiceGuideQuestion('هل  أنت المالك لهذة القطعة الأرضية ؟', true, [ServiceGuideAnswer('نعم', 'question_owner_land-Y'), ServiceGuideAnswer('لا', 'question_owner_land-N')]),
    ServiceGuideQuestion('هل لديك شركاء   ؟', true, [ServiceGuideAnswer('نعم', 'request_co_partners-Y'), ServiceGuideAnswer('لا', 'request_co_partners-N')]),
    ServiceGuideQuestion('هل أرضية المشروع بحاجة إلى تثبيت؟', true, [ServiceGuideAnswer('نعم', 'project_land-Y'), ServiceGuideAnswer('لا', 'project_land-N')]),
  ],
  '000000201400010000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ماهو نوع العقار؟', true, [ServiceGuideAnswer('مالك', 'what_is_property_type-1'), ServiceGuideAnswer('مستأجر', 'what_is_property_type-2')]),
    ServiceGuideQuestion('الاحتياجات المائية  استخدام المياه', true, [ServiceGuideAnswer('منزلية', 'water_needs_or_use-1'), ServiceGuideAnswer('صناعية', 'water_needs_or_use-2')]),
  ],
  '000000201400020000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('ماهو نوع العقار؟', true, [ServiceGuideAnswer('مالك', 'what_is_property_type-1'), ServiceGuideAnswer('مستأجر', 'what_is_property_type-2')]),
    ServiceGuideQuestion('ماهو نوع مياه الصرف الصحي؟', true, [ServiceGuideAnswer('منزلية', 'what_waste_water_type-1'), ServiceGuideAnswer('صناعية', 'what_waste_water_type-2')]),
  ],
  '000000200301050000': [
    ServiceGuideQuestion('ماذا تفعل هذه الخدمة؟', false, []),
    ServiceGuideQuestion('نوع مقدم الطلب', false, [ServiceGuideAnswer('الشخص الطبيعي', 'AcCouNt_tYPe_ApplicantType-natural_person_W'), ServiceGuideAnswer('الكيان القانوني', 'AcCouNt_tYPe_ApplicantType-legal_person_W')]),
    ServiceGuideQuestion('هل تقدم طلب معلومات على الاجراء أوخارج الاجراء ؟', true, [ServiceGuideAnswer('على الاجراء (طلب بشأن الملكية)', 'you_applying_formality-1'), ServiceGuideAnswer('خارج الاجراء (طلب بشأن المالك)', 'you_applying_formality-2')]),
    ServiceGuideQuestion('هل أنت مالك هذا العقار ؟', true, [ServiceGuideAnswer('لا', 'owner_of_the_property-0'), ServiceGuideAnswer('نعم', 'owner_of_the_property-1')]),
    ServiceGuideQuestion('هل تتقدم بالطلب لفائدة؟', true, [ServiceGuideAnswer('شخص طبيعي', 'person_type_applying_for-natural_person'), ServiceGuideAnswer('شخص اعتباري', 'person_type_applying_for-moral_person')]),
  ],
  '000000200500010003': [
    ServiceGuideQuestion('اعادة إصدار بطاقة الأشخاص ذوي الاحتياجات الخاصة تتضمن إصدار بطاقة جديدة بدلاً من القديمة. قد يكون ذلك ضروريًا في حالة فقدان البطاقة أو سرقتها أو تلفها. (بموجب القانون رقم 25-01 المؤرخ 20 فبراير 2025 المتعلق بحماية ورعاية الأشخاص ذوي الاحتياجات الخاصة)', false, []),
    ServiceGuideQuestion('ما هي علاقتك بالشخص ذي الاحتياجات الخاصة؟', true, [ServiceGuideAnswer('المستفيد', 'person_relationship_needs-1'), ServiceGuideAnswer('والدي المستفيد ( الابن أقل من 18 سنة)', 'person_relationship_needs-2'), ServiceGuideAnswer('احد الأبناء البالغين للمستفيد', 'person_relationship_needs-3'), ServiceGuideAnswer('الوصي القانوني (من غيرأحد الوالدين) للمستفيد ( الابن أقل من 18 سنة)', 'person_relationship_needs-4'), ServiceGuideAnswer('موكل من المستفيد لطلب الخدمة بالنيابة عنه', 'person_relationship_needs-5'), ServiceGuideAnswer('موكل من ولي أمر المستفيد ( الابن أقل من 18 سنة) لطلب الخدمة نيابة عنه', 'person_relationship_needs-6')]),
    ServiceGuideQuestion('نوع الطلب؟', true, [ServiceGuideAnswer('بطاقة  ضائعة', 'application_type-1'), ServiceGuideAnswer('بطاقة تالفة', 'application_type-2')]),
  ],
};