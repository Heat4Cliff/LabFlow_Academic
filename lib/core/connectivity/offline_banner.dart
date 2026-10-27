import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_cubit.dart';
import 'connectivity_state.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ConnectivityCubit, ConnectivityState>(
    builder: (context, state) {
      if (!state.isOffline) return child;
      return SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFFFE7B3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 17,
                    color: Color(0xFF533600),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline mode · Data yang tersedia berasal dari cache.',
                      style: TextStyle(
                        color: Color(0xFF533600),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    },
  );
}
