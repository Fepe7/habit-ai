import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../levels/presentation/category_l10n.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../domain/community_template_model.dart';

// Card de plantilla para el feed de la comunidad
class CommunityTemplateCard extends StatelessWidget {
  final CommunityTemplateModel template;
  final VoidCallback onTap;

  const CommunityTemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = AppTheme.categoryBg(template.category, scheme.brightness);
    final fgColor = AppTheme.categoryFg(template.category, scheme.brightness);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // emoji o icono de categoria
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: template.emoji != null
                    ? Text(template.emoji!,
                        style: const TextStyle(fontSize: 26))
                    : Icon(
                        AppTheme.categoryIcon(template.category),
                        size: 24,
                        color: fgColor,
                      ),
              ),
              const SizedBox(width: 14),

              // info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    if (template.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        template.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // avatar del autor
                        AvatarCircle(
                          initials: AvatarCircle.fromName(
                            template.authorDisplayName.isNotEmpty
                                ? template.authorDisplayName
                                : template.authorUsername,
                            null,
                          ),
                          size: 18,
                          photoUrl: template.authorPhotoUrl,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            template.authorDisplayName.isNotEmpty
                                ? template.authorDisplayName
                                : '@${template.authorUsername}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // habitos
                        Icon(Icons.checklist_rounded,
                            size: 13, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${template.habitCount}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        // importaciones
                        Icon(Icons.download_rounded,
                            size: 13, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${template.importCount}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // chip de categoria
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  CategoryL10n.labelOf(template.category, context),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
