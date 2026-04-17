import 'package:flutter/material.dart';

/// Wrapper de `showModalBottomSheet` con defaults seguros para HabitAI.
/// `useRootNavigator: true` empuja el sheet al Navigator raíz (por encima
/// de la BottomNavigationBar del MainShell). Sin esto el sheet queda
/// tapado por la nav porque ShellRoute usa un Navigator interno.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: true,
    backgroundColor: backgroundColor,
    shape: shape,
    constraints: constraints,
  );
}
