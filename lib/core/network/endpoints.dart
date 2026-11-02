/// Endpoint paths for the DZDS portal and SSO, extracted from the captured
/// traffic. Kept in one place so the rest of the code never hardcodes URLs.
class Endpoints {
  Endpoints._();

  // ---------------------------------------------------------------------
  // dzds.dz — NextAuth
  // ---------------------------------------------------------------------
  static const String authProviders = '/api/auth/providers';
  static const String authCsrf = '/api/auth/csrf';
  static const String authSession = '/api/auth/session';
  static const String authSigninCms = '/api/auth/signin/cms';
  static const String authCallbackCms = '/api/auth/callback/cms';

  // ---------------------------------------------------------------------
  // dzds.dz — user / messages / system
  // ---------------------------------------------------------------------
  static const String userGet = '/api/user/get';
  static const String userAvatar = '/api/user/get-avatar';
  static const String userValidateLicense = '/api/user/validate-user-license';
  static const String cmsSystem = '/api/cms-rest/hoox/cms/client/system/v1/system';
  static const String chatLogList = '/api/cms-rest/chat-log-list-query';
  static const String msgContentCount = '/api/goms-rest/receive-msg-content-count';

  // ---------------------------------------------------------------------
  // dzds.dz — CAP service engine (browse → apply → submit → certificate)
  // ---------------------------------------------------------------------
  static const String serviceSceneConfig =
      '/api/cap-rest/service-scene-config-get';
  static const String singleSceneGuide =
      '/api/cap-rest/hoox/cap/online/pc/config/service/v1/single-scene-guide-get';
  static const String sceneInstanceAdd = '/api/cap-rest/scene-instance-add';
  static const String apasinfoBasicGet =
      '/api/cap-rest/hoox/cap/online/pc/single/declare/v1/apasinfo-basic-get';
  static const String apasinfoResultGet =
      '/api/cap-rest/hoox/cap/online/pc/single/declare/v1/apasinfo-result-get';
  static const String apasinfoFormTemporary =
      '/api/cap-rest/hoox/cap/online/pc/single/declare/v1/apasinfo-form-temporary';
  static const String apasinfoFormSave =
      '/api/cap-rest/hoox/cap/online/pc/single/declare/v1/apasinfo-form-save';
  static const String apasinfoRegister = '/api/cap-rest/apasinfo-register';
  static const String payInfoList =
      '/api/cap-rest/hoox/cap/online/pc/single/pay/v1/pay-info-list';
  static const String evaluateList =
      '/api/cap-rest/hoox/cap/online/pc/single/evaluate/v1/evaluate-list';
  static const String licenseList = '/api/cap-rest/license-list';
  static const String licenseDetail = '/api/cap-rest/license-detail';
  static const String canDownloadLicense = '/api/cap-rest/can-download-license';
  static const String canDownloadLicenseV2 =
      '/api/cap-rest/can-download-license-v2';
  static const String downloadLicenseFile =
      '/api/cap-download-license-file-by-info-v2';
  static const String capBillGet = '/api/cap-bill-get';

  // ---------------------------------------------------------------------
  // dzds.dz — form engine (well-form)
  // ---------------------------------------------------------------------
  static const String formFillTable = '/formCenter/well-form/fill-in/table';
  static const String formAuthConfig = '/formCenter/well/form/auth/config';
  static const String formDecideFillSurvey =
      '/formCenter/well/form/filling/decideFillServey';
  static const String formGetAffairRela =
      '/formCenter/well/form/filling/get-form-affair-rela';
  static const String formGetValidStatus =
      '/formCenter/well/form/filling/get-valid-status-by-id';
  static const String formGetData =
      '/formCenter/well/form/filling/form-meta/get-form-data';
  static const String formApiQuery =
      '/formCenter/well/form/filling/formApiQueryByValue';
  static const String formGetSelection =
      '/formCenter/well/form/filling/getSelectionRelationDataByValue';
  static const String formCheckExpression =
      '/formCenter/well/form/filling/checkExpressionByValue';
  static const String formSave =
      '/formCenter/well/form/filling/saveByValue';
  static const String formCheckAndSave =
      '/formCenter/well/form/filling/formCheckExpressionAndSaveByValue';

  // ---------------------------------------------------------------------
  // sso.dzds.dz — identity provider
  // ---------------------------------------------------------------------
  static const String idpOauthAuthorize = '/idp/outside/oauth2/authorize';
  static const String idpAuthenticate = '/idp/authCenter/authenticate';
  static const String idpGetSignature = '/idp/pt/auth/getSignature';
  static const String idpQueryAuthMethods = '/idp/authn/queryAuthMethods';
  static const String idpCaptchaCheckOpen = '/idp/captcha/checkOpen';
  static const String idpCaptchaGetPuzzle = '/idp/captcha/getBlockPuzzle';
  static const String idpCheckCaptcha = '/idp/anonymous/checkCaptcha';
  static const String idpSendSms = '/idp/authn/sendSmsMsg';
  static const String idpVerifyCodeIsNeed = '/idp/authn/verifyCodeIsNeed';
  static const String idpAuthExecute = '/idp/authn/authExecute';
  static const String idpAuthnEngine = '/idp/authCenter/authnEngine';
  static const String idpLocaleConfig = '/idp/authCenter/getLocaleConfig';
  static const String idpAgreementConfig = '/idp/agreement/getConfig';

  // ---------------------------------------------------------------------
  // sso.dzds.dz — new-account registration (userRegister + notification)
  // ---------------------------------------------------------------------
  static const String idpRegisterNaturalPerson =
      '/idp/userRegister/naturalPersonAttributesQuery';
  static const String idpRegisterDocumentAttributes =
      '/idp/userRegister/documentAttributesQuery';
  static const String idpRegisterDict = '/idp/userRegister/getComponentData';
  static const String idpRegisterCities =
      '/idp/userRegister/getComponentDataByParentId';
  // The registration is a two-step flow (changed server-side in Sep 2026):
  //  1. saveUserFirst  — identity verification + captcha → returns a token
  //  2. saveUserSubmit — account credentials + SMS code → creates the account
  static const String idpRegisterSaveUser = '/idp/userRegister/saveUser';
  static const String idpRegisterSaveUserFirst =
      '/idp/userRegister/saveUserFirst';
  static const String idpRegisterSaveUserSubmit =
      '/idp/userRegister/saveUserSubmit';
  static const String idpNotifyCaptchaConf = '/idp/anonymous/getCaptchaConf';
  static const String idpNotifyGetCaptcha = '/idp/notification/getCaptcha';
  static const String idpNotifySendSecurityCode =
      '/idp/notification/sendSecurityCode';
}
