import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/session_bloc.dart';
import '../core/logging/app_loggers.dart';

/// Simple display-only timer widget that gets all state from SessionBloc
/// and emits direct BLoC events for user interactions
class PracticeTimerDisplayWidget extends StatelessWidget {
  final bool enabled;
  final bool showSkipButton; // Whether to show skip button

  const PracticeTimerDisplayWidget({
    super.key,
    this.enabled = true,
    this.showSkipButton = false,
  });

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        // Default values for when no session is active
        bool timerIsRunning = false;
        int timerDisplaySeconds = 0;
        bool isInWarmup = false;

        // Get timer state from SessionBloc
        if (state is SessionActive) {
          timerIsRunning = state.timerIsRunning;
          timerDisplaySeconds = state.timerDisplaySeconds;
          isInWarmup = state.isInWarmup;
        }

        final display = Duration(seconds: timerDisplaySeconds);
        final timerDisplay = _formatTime(display);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer Display
            Text(
              timerDisplay,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            // Control Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip Button (left side)
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child:
                        showSkipButton
                            ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
                                  onPressed:
                                      enabled
                                          ? () {
                                            AppLoggers.system.debug(
                                              'Practice timer SKIP button clicked',
                                            );
                                            context.read<SessionBloc>().add(
                                              TimerSkipPressed(),
                                            );
                                          }
                                          : null,
                                ),
                                const Text("Skip"),
                              ],
                            )
                            : const SizedBox.shrink(),
                  ),
                ),
                // Start/Stop Button (center)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: RawMaterialButton(
                    onPressed:
                        enabled
                            ? () {
                              if (timerIsRunning) {
                                AppLoggers.system.debug(
                                  'Practice timer STOP button clicked',
                                );
                                context.read<SessionBloc>().add(
                                  TimerStopPressed(),
                                );
                              } else {
                                AppLoggers.system.debug(
                                  'Practice timer START button clicked',
                                );
                                context.read<SessionBloc>().add(
                                  TimerStartPressed(),
                                );
                              }
                            }
                            : null,
                    shape: const CircleBorder(),
                    fillColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      timerIsRunning ? Icons.pause : Icons.play_arrow,
                      size: 40,
                    ),
                  ),
                ),
                // Done Button (right side)
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.done_all_outlined),
                          onPressed:
                              enabled && !isInWarmup
                                  ? () {
                                    AppLoggers.system.debug(
                                      'Practice timer DONE button clicked',
                                    );
                                    context.read<SessionBloc>().add(
                                      TimerDonePressed(),
                                    );
                                  }
                                  : null,
                        ),
                        const Text("Done"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}
