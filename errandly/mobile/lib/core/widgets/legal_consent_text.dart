import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../utils/url_helper.dart';

class LegalConsentText extends StatelessWidget {
  final Color? textColor;
  final bool centered;

  const LegalConsentText({super.key, this.textColor, this.centered = true});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.textMuted;
    final linkStyle = TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12);

    return Text.rich(
      TextSpan(
        style: TextStyle(color: color, fontSize: 12, height: 1.4),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => UrlHelper.open(context, AppConstants.termsOfServiceUrl),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => UrlHelper.open(context, AppConstants.privacyPolicyUrl),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: centered ? TextAlign.center : TextAlign.start,
    );
  }
}
