import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dary/services/theme_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';

    final now = DateTime.now();
    final formattedDate = isArabic 
        ? DateFormat('d MMMM yyyy', 'ar').format(now)
        : DateFormat.yMMMMd('en_US').format(now);

    final englishText = '''
Last updated: $formattedDate

Thank you for using Dary (“we”, “our”, or “us”). We respect your privacy and are committed to protecting your personal information.

1. Information We Collect

We collect the following information when you use our app:
• Personal Information:
Your name, email address, phone number, and login credentials.
• Payment Information:
Payment details such as credit/debit card number, billing address, and transaction information.
(Note: Payments are processed securely via Ma'amalat, and we do not store your full payment details.)
• Usage Data:
Information about how you use the app, including device information, IP address, and activity logs.

2. How We Use Your Information

We use your information to:
• Provide and improve our services.
• Manage your account and process payments.
• Communicate with you about your account, transactions, and updates.
• Ensure security and prevent fraud.
• Comply with legal obligations.

2.1 Payment Information

We use Ma’amalat, a trusted payment processing partner in Libya, to handle payments within the app. When you make a payment via Visa card or bank transfer, you will be redirected to a secure payment page provided by Ma’amalat.
• Your payment information is handled directly by Ma’amalat. We do not store your credit card details or sensitive payment data within our app.
• All payment transactions are conducted over a secure (HTTPS) connection.
• If you have any questions or issues regarding payments, you can contact Ma’amalat’s support team or reach out to us for assistance.

3. Data Sharing

We do not sell your personal information to third parties. We may share your data with trusted service providers who help us operate the app, such as payment processors, analytics providers, and customer support services. All partners are obligated to keep your information confidential.

4. Security

We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.

5. Your Rights

Depending on your location, you may have the right to:
• Access, correct, or delete your personal data.
• Object to or restrict certain data processing.
• Withdraw your consent at any time.

To exercise your rights, please contact us at: support@dary.ly.

6. Children’s Privacy

Our app is not intended for children under 13 years old. We do not knowingly collect personal information from children under 13.

7. Changes to This Privacy Policy

We may update this policy from time to time. We will notify you of any significant changes by posting the new Privacy Policy on this page.

⸻

If you have any questions about this Privacy Policy, please contact us at:
support@dary.ly
''';

    final arabicText = '''
آخر تحديث: $formattedDate

شكرًا لاستخدامك تطبيق Dary (“نحن” أو “لنا”). نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.

1. المعلومات التي نجمعها

نقوم بجمع المعلومات التالية عند استخدامك للتطبيق:
• المعلومات الشخصية:
الاسم، البريد الإلكتروني، رقم الهاتف، وبيانات تسجيل الدخول الخاصة بك.
• معلومات الدفع:
تفاصيل الدفع مثل رقم بطاقة الائتمان/الخصم، عنوان الفوترة، ومعلومات المعاملات.
(ملاحظة: تتم معالجة المدفوعات بأمان عبر معاملات، ولا نقوم بتخزين تفاصيل الدفع الكاملة.)
• بيانات الاستخدام:
معلومات حول كيفية استخدامك للتطبيق، بما في ذلك معلومات الجهاز، عنوان IP، وسجلات النشاط.

2. كيفية استخدامنا لمعلوماتك

نستخدم معلوماتك لـ:
• تقديم خدماتنا وتحسينها.
• إدارة حسابك ومعالجة المدفوعات.
• التواصل معك بشأن حسابك والمعاملات والتحديثات.
• ضمان الأمان ومنع الاحتيال.
• الامتثال للالتزامات القانونية.

2.1 معلومات الدفع

نستخدم شركة معاملات كشريك موثوق لمعالجة المدفوعات داخل التطبيق. عند إجراء عملية دفع عبر بطاقة الفيزا أو التحويل البنكي، يتم توجيهك إلى صفحة الدفع الآمنة الخاصة بشركة معاملات.
• بيانات الدفع الخاصة بك يتم التعامل معها مباشرة من قبل شركة معاملات، ونحن لا نخزن معلومات بطاقتك البنكية أو بيانات الدفع الحساسة في التطبيق.
• جميع عمليات الدفع تتم عبر اتصال آمن (HTTPS).
• في حالة وجود أي استفسارات أو مشاكل بخصوص الدفع، يمكنك التواصل مع فريق دعم معاملات أو عبرنا.

3. مشاركة البيانات

نحن لا نبيع معلوماتك الشخصية لأي طرف ثالث. قد نشارك بياناتك مع مزودي خدمات موثوقين يساعدوننا في تشغيل التطبيق، مثل مزودي الدفع، ومزودي التحليلات، وخدمات دعم العملاء. جميع الشركاء ملزمون بالحفاظ على سرية معلوماتك.

4. الأمان

نطبق التدابير الفنية والتنظيمية المناسبة لحماية بياناتك الشخصية من الوصول غير المصرح به أو التعديل أو الكشف أو التدمير.

5. حقوقك

حسب موقعك، قد تكون لديك حقوق مثل:
• الوصول إلى بياناتك الشخصية وتصحيحها أو حذفها.
• الاعتراض على أو تقييد بعض عمليات معالجة البيانات.
• سحب موافقتك في أي وقت.

للمطالبة بحقوقك، يرجى التواصل معنا على: support@dary.ly.

6. خصوصية الأطفال

تطبيقنا غير موجه للأطفال دون 13 سنة. نحن لا نجمع عن عمد معلومات شخصية من الأطفال تحت هذا العمر.

7. التغييرات على سياسة الخصوصية

قد نقوم بتحديث هذه السياسة من وقت لآخر. سنبلغك بأي تغييرات جوهرية عن طريق نشر سياسة الخصوصية الجديدة على هذه الصفحة.

⸻

إذا كان لديك أي استفسار حول سياسة الخصوصية هذه، يرجى التواصل معنا على:
support@dary.ly
''';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          isArabic ? arabicText : englishText,
          style: ThemeService.getDynamicStyle(context, fontSize: 16, height: 1.5),
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
        ),
      ),
    );
  }
}
