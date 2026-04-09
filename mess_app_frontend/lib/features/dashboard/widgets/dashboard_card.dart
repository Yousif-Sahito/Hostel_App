import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackgroundColor ?? const Color(0xFFE3F2FD),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color:
                      iconColor ??
                      theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 26,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
