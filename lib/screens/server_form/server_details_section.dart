import 'package:flutter/cupertino.dart';

class ServerDetailsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController hostController;
  final TextEditingController portController;
  final VoidCallback onChanged;

  const ServerDetailsSection({
    super.key,
    required this.nameController,
    required this.hostController,
    required this.portController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection(
      header: const Text('SERVER DETAILS'),
      children: [
        CupertinoTextFormFieldRow(
          controller: nameController,
          placeholder: 'My TrueNAS Server',
          prefix: const Text('Name'),
          onChanged: (_) => onChanged(),
        ),
        CupertinoTextFormFieldRow(
          controller: hostController,
          placeholder: '192.168.1.100',
          prefix: const Text('Host'),
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
        ),
        CupertinoTextFormFieldRow(
          controller: portController,
          placeholder: 'Default port (443 for HTTPS, 80 for HTTP)',
          prefix: const Text('Port'),
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
