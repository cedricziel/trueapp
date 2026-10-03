import 'package:flutter/cupertino.dart';

class LocalNetworkSection extends StatelessWidget {
  final TextEditingController localUrlController;
  final VoidCallback onChanged;

  const LocalNetworkSection({
    super.key,
    required this.localUrlController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection(
      header: const Text('LOCAL NETWORK (OPTIONAL)'),
      children: [
        CupertinoTextFormFieldRow(
          controller: localUrlController,
          placeholder: 'http://192.168.1.100:80',
          prefix: const Text('Local URL'),
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
