import 'package:flutter/cupertino.dart';

class TrustedWifiSection extends StatelessWidget {
  final String? currentSsid;
  final bool isLoadingCurrentSsid;
  final List<String> trustedSsids;
  final TextEditingController ssidController;
  final VoidCallback onSsidChanged;
  final VoidCallback onAddSsid;
  final VoidCallback onAddCurrent;
  final VoidCallback onDetect;
  final ValueChanged<String> onRemove;

  const TrustedWifiSection({
    super.key,
    required this.currentSsid,
    required this.isLoadingCurrentSsid,
    required this.trustedSsids,
    required this.ssidController,
    required this.onSsidChanged,
    required this.onAddSsid,
    required this.onAddCurrent,
    required this.onDetect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final current = currentSsid;
    return CupertinoFormSection(
      header: const Text('TRUSTED WI-FI NETWORKS'),
      children: [
        if (current != null && !trustedSsids.contains(current))
          CupertinoFormRow(
            prefix: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Network'),
                Text(
                  current,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAddCurrent,
              child: const Text('Add Current'),
            ),
          ),
        if (current == null && !isLoadingCurrentSsid)
          CupertinoFormRow(
            prefix: const Text('Current Network'),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDetect,
              child: const Text('Detect'),
            ),
          ),
        if (isLoadingCurrentSsid)
          const CupertinoFormRow(
            prefix: Text('Current Network'),
            child: CupertinoActivityIndicator(),
          ),
        CupertinoFormRow(
          prefix: const Text('Add SSID'),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: ssidController,
                  placeholder: 'Wi-Fi network name',
                  onChanged: (_) => onSsidChanged(),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onAddSsid,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        ...trustedSsids.map(
          (ssid) => CupertinoFormRow(
            prefix: Text(ssid),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onRemove(ssid),
              child: const Text('Remove'),
            ),
          ),
        ),
      ],
    );
  }
}
