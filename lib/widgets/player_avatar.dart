import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/models/models.dart';

/// Player avatar widget with navigation to profile
class PlayerAvatar extends StatelessWidget {
  final User user;
  final double radius;
  final bool showName;
  final bool clickable;

  const PlayerAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.showName = false,
    this.clickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.withValues(alpha: 0.2),
      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
      child: user.photoUrl == null
          ? Icon(Icons.person, size: radius, color: Colors.blue)
          : null,
    );

    if (!clickable) {
      if (showName) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 4),
            Text(
              user.name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }
      return avatar;
    }

    final widget = showName
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: 4),
              Text(
                user.name,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        : avatar;

    return InkWell(
      onTap: () => context.push('/profile/${user.uid}'),
      borderRadius: BorderRadius.circular(radius),
      child: widget,
    );
  }
}

