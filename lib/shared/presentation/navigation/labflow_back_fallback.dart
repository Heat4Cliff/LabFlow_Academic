import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void popOrGo(BuildContext context, String fallbackPath) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackPath);
  }
}

class LabFlowBackFallback extends StatelessWidget {
  const LabFlowBackFallback({
    required this.fallbackPath,
    required this.child,
    super.key,
  });

  final String fallbackPath;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: context.canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !context.canPop()) context.go(fallbackPath);
    },
    child: child,
  );
}
