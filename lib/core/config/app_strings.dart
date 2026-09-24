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

  // Story studio
  static const String studioTitle = 'Story Studio';
  static const String studioTitleAr = 'استوديو القصة';
  static const String studioHint = 'Record up to 60 seconds of you telling your story.';
  static const String studioHintAr = 'سجّل حتى 60 ثانية من فيديو تحكي فيه قصتك.';
  static const String captionLabel = 'Caption (optional)';
  static const String captionLabelAr = 'وصف القصة (اختياري)';
  static const String publishStory = 'Publish story';
  static const String publishStoryAr = 'نشر القصة';
  static const String pickFromGallery = 'Pick from gallery';
  static const String pickFromGalleryAr = 'اختر من المعرض';
  static const String storyTooLong = 'Story must be up to 60 seconds.';
  static const String storyTooLongAr = 'القصة يجب ألا تتجاوز 60 ثانية.';
  static const String publishedSuccess = 'Your story was published';
  static const String publishedSuccessAr = 'تم نشر قصتك بنجاح';

  // My stories
  static const String myStories = 'My stories';
  static const String myStoriesAr = 'قصصي';
  static const String noStories = 'No stories yet';
  static const String noStoriesAr = 'لا توجد قصص بعد';
  static const String noStoriesHint = 'Tell your story in 60 seconds — employers are watching.';
  static const String noStoriesHintAr = 'احكِ قصتك في 60 ثانية — أصحاب العمل ينتظرون.';
  static const String createStoryCta = 'Create story';
  static const String createStoryCtaAr = 'إنشاء قصة';
  static const String deleteStory = 'Delete story';
  static const String deleteStoryAr = 'حذف القصة';
  static const String addingVideoNote = 'ملاحظة: تتوفر الكاميرا على الأجهزة الفعلية فقط.';

  static String pickFailed(bool isAr) =>
      isAr ? 'تعذّر اختيار الملف، حاول مجدداً.' : 'Could not open the picker.';

  // Phase 3 — feed & interactions
  static const String explore = 'Explore';
  static const String exploreAr = 'استكشف';
  static const String exploreHint = 'Browse candidate stories like TikTok.';
  static const String exploreHintAr = 'تصفّح قصص المرشحين مثل تيك توك.';
  static const String feedEmpty = 'No stories yet';
  static const String feedEmptyAr = 'لا توجد قصص بعد';
  static const String feedEmptyHint = 'Approved seeker stories will show up here.';
  static const String feedEmptyHintAr = 'قصص الباحثين المعتمدة تظهر هنا.';
  static const String viewProfile = 'View profile';
  static const String viewProfileAr = 'عرض الملف';
  static const String candidates = 'Saved candidates';
  static const String candidatesAr = 'المرشحون';
  static const String candidatesHint = 'Candidates you save from the feed.';
  static const String candidatesHintAr = 'المرشحون الذين تحفظهم من التغذية.';
  static const String noCandidates = 'No saved candidates yet';
  static const String noCandidatesAr = 'لا يوجد مرشحون محفوظون بعد';
  static const String saved = 'Saved';
  static const String savedAr = 'محفوظ';
  static const String saveSeeker = 'Save candidate';
  static const String saveSeekerAr = 'حفظ المرشح';
  static const String contact = 'Contact';
  static const String contactAr = 'تواصل';
}