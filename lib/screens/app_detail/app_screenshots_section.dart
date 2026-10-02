import 'package:flutter/cupertino.dart';

class AppScreenshotsSection extends StatefulWidget {
  final List<String> screenshots;

  const AppScreenshotsSection({super.key, required this.screenshots});

  @override
  State<AppScreenshotsSection> createState() => _AppScreenshotsSectionState();
}

class _AppScreenshotsSectionState extends State<AppScreenshotsSection> {
  int _selectedScreenshot = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshots',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: CupertinoColors.systemGrey6.resolveFrom(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.screenshots[_selectedScreenshot],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Screenshot unavailable',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CupertinoActivityIndicator());
              },
            ),
          ),
        ),
        if (widget.screenshots.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.screenshots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedScreenshot;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedScreenshot = index;
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.separator.resolveFrom(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.screenshots[index],
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: CupertinoColors.systemGrey6.resolveFrom(
                              context,
                            ),
                            child: Icon(
                              CupertinoIcons.photo,
                              size: 24,
                              color: CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
