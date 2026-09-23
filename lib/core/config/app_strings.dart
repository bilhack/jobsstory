/// Centralized strings — English + Arabic.
/// Phase 0 uses embedded strings; real i18n (ARB files) comes with Phase 1.
class AppStrings {
  AppStrings._();

  static const String appName = 'JobsStory';
  static const String appNameAr = 'جوبز ستوري';

  static const String sloganEn = "Don't send a CV. Tell your story.";
  static const String sloganAr = 'لا ترسل سيرة ذاتية... احكِ قصتك.';

  static const String ctaStart = 'Get Started';
  static const String ctaStartAr = 'ابدأ الآن';

  static const String welcomeTagline = '60 seconds of you. Seen by the world.';
  static const String onboardingTitle = 'Who are you?';
  static const String onboardingTitleAr = 'من أنت؟';
  static const String onboardingSubtitle = 'اختر دورك وابدأ رحلتك.';
  static const String roleSeeker = 'Job Seeker';
  static const String roleSeekerAr = 'باحث عن عمل';
  static const String roleSeekerDesc = 'Tell your story as a 60-second video and get discovered.';
  static const String roleRecruiter = 'Recruiter';
  static const String roleRecruiterAr = 'مسؤول توظيف';
  static const String roleRecruiterDesc = 'Watch stories instead of reading piles of CVs.';

  // Auth
  static const String loginTitle = 'Welcome back';
  static const String loginTitleAr = 'مرحباً بعودتك';
  static const String emailLabel = 'Email';
  static const String emailLabelAr = 'البريد الإلكتروني';
  static const String passwordLabel = 'Password';
  static const String passwordLabelAr = 'كلمة المرور';
  static const String nameLabel = 'Full name';
  static const String nameLabelAr = 'الاسم الكامل';
  static const String loginButton = 'Log in';
  static const String loginButtonAr = 'تسجيل الدخول';
  static const String registerButton = 'Create account';
  static const String registerButtonAr = 'إنشاء حساب';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithGoogleAr = 'المتابعة عبر Google';
  static const String noAccount = 'Don\'t have an account?';
  static const String haveAccount = 'Already have an account?';
  static const String createAccountCta = 'Create account';
  static const String signInCta = 'Log in';
  static const String registerTitle = 'Create your account';
  static const String registerTitleAr = 'أنشئ حسابك';
  static const String registerRoleHint = 'You are joining as';
  static const String registerRoleHintAr = 'تنضم الآن كـ';

  // Home
  static const String homeHello = 'Hey';
  static const String homeHelloAr = 'أهلاً';
  static const String signOut = 'Sign out';
  static const String signOutAr = 'تسجيل الخروج';
  static const String roleSelected = 'Role selected';
  static const String roleSelectedAr = 'تم اختيار الدور';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String genericErrorAr = 'حدث خطأ ما، حاول مجدداً.';
  static const String emailInUseError = 'This email is already registered.';
  static const String wrongPasswordError = 'Incorrect email or password.';
  static const String weakPasswordError = 'Password must be at least 6 characters.';
  static const String fillAllFields = 'Please fill all fields.';
  static const String invalidEmailError = 'Please enter a valid email address.';
}