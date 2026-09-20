import 'package:flutter/cupertino.dart';

/// The TrueNAS Manager logo tile, sized in logical pixels.
class AppLogo extends StatelessWidget {
  static const assetPath = 'assets/branding/logo.png';

  final double size;

  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TrueNAS Manager logo',
      image: true,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
