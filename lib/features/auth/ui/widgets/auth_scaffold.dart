import 'package:cuboid_flutter_template/features/auth/ui/widgets/auth_styles.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.body,
    this.onBack,
    this.padding = const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
  });

  final Widget body;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AuthStyles.backgroundDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBack != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: s8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.chevron_back,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: s4),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: s16),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
