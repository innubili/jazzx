import 'package:flutter/material.dart';

// TARGET LAYOUT PROPORTIONS:
//
// PORTRAIT MODE:
// - App bar: 5%
// - Session pane: 36%
// - Practice details: 48%
// - Practice mode buttons: 10%
//
// LANDSCAPE MODE:
// - App bar (on top): 100%
// - Practice mode buttons: 8% (left)
// - Session pane: 50% (center)
// - Practice details: 35% (right)

import '../widgets/practice_mode_buttons_widget.dart';
import '../widgets/practice_detail_widget.dart';
import '../widgets/main_drawer.dart';
import '../models/practice_category.dart';
import '../models/link.dart';
import '../screens/session_review_screen.dart';
import '../widgets/add_manual_session_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/session_bloc.dart';
import '../models/session.dart';
import '../providers/user_profile_provider.dart';
import '../utils/draft_utils.dart';
import 'package:collection/collection.dart';
import '../widgets/practice_timer_display_widget.dart';
import '../widgets/metronome_widget.dart';
import '../widgets/metronome_controller.dart';

import 'dart:async';
import '../core/logging/app_loggers.dart';
import '../utils/utils.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionBloc _bloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    AppLoggers.system.info('SessionScreen initState called');

    try {
      _bloc = SessionBloc();
      AppLoggers.system.info('SessionBloc created successfully');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        AppLoggers.system.info('SessionScreen postFrameCallback executing');

        // Use proper BLoC architecture - let BLoC handle initialization
        _bloc.add(SessionInitialize());
        AppLoggers.system.info('SessionInitialize event added to bloc');

        setState(() {
          _initialized = true;
        });
        AppLoggers.system.info('SessionScreen initialization completed');
      });
    } catch (e, stack) {
      AppLoggers.error.error(
        'SessionScreen initState failed',
        error: e.toString(),
        stackTrace: stack.toString(),
      );
    }
  }

  @override
  void dispose() {
    AppLoggers.system.info('SessionScreen disposing');
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLoggers.system.info(
      'SessionScreen build called, initialized: $_initialized',
    );

    if (!_initialized) {
      AppLoggers.system.info('SessionScreen showing loading indicator');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    AppLoggers.system.info('SessionScreen showing main content');
    return BlocProvider.value(value: _bloc, child: const _SessionScreenView());
  }
}

class _SessionScreenView extends StatefulWidget {
  const _SessionScreenView();

  @override
  State<_SessionScreenView> createState() => _SessionScreenViewState();
}

class _SessionScreenViewState extends State<_SessionScreenView> {
  late final MetronomeController _metronomeController;
  Timer? _autoSaveTimer;

  Timer? _debouncedSaveTimer;

  @override
  void initState() {
    super.initState();
    _metronomeController = MetronomeController();

    // Start auto-save timer (save every 60 seconds during active session - less frequent)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _performAutoSave();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _debouncedSaveTimer?.cancel();
    super.dispose();
  }

  void _performAutoSave() {
    final sessionBloc = context.read<SessionBloc>();
    final currentState = sessionBloc.state;

    // Only auto-save for active sessions that haven't been completed
    if (currentState is SessionActive && !currentState.isPaused) {
      // Use debounced save to avoid excessive state emissions
      _debouncedSaveTimer?.cancel();
      _debouncedSaveTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        // Use proper BLoC architecture - let BLoC handle auto-save and draft logic
        sessionBloc.add(SessionAutoSaveWithDraft());
      });
    }
  }

  /// Consolidated practice mode button handler to avoid code duplication
  /// between portrait and landscape modes
  Widget _buildPracticeModeButtons(
    BuildContext context,
    PracticeCategory currentPracticeCategory,
    Orientation orientation,
  ) {
    return PracticeModeButtonsWidget(
      currentPracticeCategory: currentPracticeCategory.name,
      queuedMode: null, // Add queued mode logic if needed
      orientation: orientation,
    );
  }

  /// Handle SessionInitializeState - check for draft sessions to continue
  void _handleSessionInitializeState(
    BuildContext context,
    SessionInitializeState state,
  ) async {
    final sessionBloc = context.read<SessionBloc>();
    final userProfileProvider = context.read<UserProfileProvider>();

    AppLoggers.system.info(
      'SessionInitializeState handled - checking for draft session to continue',
    );

    // Check if there's a draft session marked for continuation
    final profile = userProfileProvider.profile;
    final draftSessionJson = profile?.preferences.draftSession;

    if (draftSessionJson != null &&
        draftSessionJson['_shouldContinue'] == true) {
      AppLoggers.system.info('Found draft session marked for continuation');

      try {
        // Remove the continuation flag and create session object
        final cleanDraftJson = Map<String, dynamic>.from(draftSessionJson);
        cleanDraftJson.remove('_shouldContinue');
        final draftSession = Session.fromJson(cleanDraftJson);

        // Clear the draft session from preferences
        final prefs = profile!.preferences;
        final newPrefs = prefs.copyWith(clearDraftSession: true);
        await userProfileProvider.saveUserPreferences(newPrefs);

        // Load the draft session into the bloc
        sessionBloc.add(SessionLoaded(draftSession));

        AppLoggers.system.info('Draft session loaded successfully');
      } catch (e) {
        AppLoggers.error.error(
          'Failed to load draft session',
          error: e.toString(),
        );
        // If loading fails, just transition to initial state
        sessionBloc.add(SessionLoaded(null));
      }
    } else {
      AppLoggers.system.info(
        'No draft session to continue - transitioning to SessionInitial',
      );
      // No draft session to continue, just transition to initial state
      sessionBloc.add(SessionLoaded(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for draft sessions immediately when BlocListener is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionBloc = context.read<SessionBloc>();
      final currentState = sessionBloc.state;

      // If we're in SessionInitializeState, trigger the draft session check
      if (currentState is SessionInitializeState) {
        AppLoggers.system.info(
          'BlocListener created, triggering draft session check',
        );
        // Manually trigger the listener logic
        _handleSessionInitializeState(context, currentState);
      }
    });

    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) async {
        // Handle SessionSavedState - perform actual save and navigation
        if (state is SessionSavedState) {
          final userProfileProvider = context.read<UserProfileProvider>();
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          try {
            // Save the session
            await userProfileProvider.saveSessionWithId(
              state.session.started.toString(),
              state.session,
            );

            // Clear any draft session
            await clearDraftSession(userProfileProvider);

            if (context.mounted) {
              // Navigate to statistics screen
              navigator.pushReplacementNamed('/statistics');
            }
          } catch (e) {
            // Handle save error
            if (context.mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error saving session: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        // Handle SessionAutoSaveWithDraftState - perform draft save
        else if (state is SessionAutoSaveWithDraftState) {
          final userProfileProvider = context.read<UserProfileProvider>();
          final session = state.session;

          // Save draft only if session has content and hasn't ended
          if (session.ended == 0) {
            saveDraftSession(userProfileProvider, session);
          }
        }
        // Handle SessionInitializeState - check for draft sessions
        else if (state is SessionInitializeState) {
          _handleSessionInitializeState(context, state);
        }
      },
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          // Timer initialization is handled by onResume callback
          // Don't automatically reset timer on every state change

          // SessionInitializeState is handled by BlocListener above
          // No fallback needed - BlocListener should handle all cases

          if (state is SessionLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is SessionInitial) {
            // Show full session screen layout but with timer disabled and no practice mode selected
            return Scaffold(
              appBar: AppBar(
                centerTitle: false,
                title: const Text('Session'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Manual entry logic here
                    },
                  ),
                ],
              ),
              drawer: const MainDrawer(),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final isPortrait =
                      constraints.maxHeight > constraints.maxWidth;
                  final title = 'Select your practice to start';

                  if (isPortrait) {
                    return SafeArea(
                      child: Column(
                        children: [
                          // --- Session Pane (flexible, 36% of available space) ---
                          Expanded(
                            flex: 36,
                            child: Padding(
                              padding: const EdgeInsets.all(.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title
                                  Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Practice Timer Widget (disabled)
                                  Flexible(
                                    flex: 3,
                                    child: PracticeTimerDisplayWidget(
                                      enabled:
                                          false, // Disabled until mode selected
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Metronome Widget
                                  Flexible(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: MetronomeWidget(
                                        controller: _metronomeController,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // --- Practice Category Details (flexible, 48% of available space) ---
                          Expanded(
                            flex: 48,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top: 0.0,
                                bottom: 4.0,
                              ),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    'Select your practice to start',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // --- Practice Mode Buttons (flexible, 10% of available space) ---
                          Expanded(
                            flex: 10,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 4.0,
                              ),
                              child: PracticeModeButtonsWidget(
                                currentPracticeCategory: null, // No selection
                                queuedMode: null,
                                orientation: Orientation.portrait,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Landscape mode: App bar at top, then 3 horizontally stacked panes
                    return SafeArea(
                      child: Row(
                        children: [
                          // --- Practice Mode Buttons (left, 8% width) ---
                          SizedBox(
                            width: constraints.maxWidth * 0.08,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PracticeModeButtonsWidget(
                                currentPracticeCategory: null, // No selection
                                queuedMode: null,
                                orientation: Orientation.landscape,
                              ),
                            ),
                          ),
                          // --- Session Pane (center, 50% width) ---
                          SizedBox(
                            width: constraints.maxWidth * 0.50,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  // Practice Timer Widget (disabled)
                                  PracticeTimerDisplayWidget(
                                    enabled:
                                        false, // Disabled until mode selected
                                  ),
                                  const SizedBox(height: 12),
                                  // Metronome Widget
                                  MetronomeWidget(
                                    controller: _metronomeController,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // --- Practice Category Details (right, 35% width) ---
                          SizedBox(
                            width: constraints.maxWidth * 0.35,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    'Select your practice to start',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            );
          }
          if (state is SessionActive) {
            // Removed unused local variable 'session' (was: final session = state.session;)
            final isOnBreak = state.isOnBreak;
            final isInWarmup = state.isInWarmup;
            final currentPracticeCategory = state.currentPracticeCategory;

            // Determine the target category for display during warmup
            final displayCategory =
                isInWarmup
                    ? (state.targetPracticeCategory ?? currentPracticeCategory)
                    : currentPracticeCategory;

            final title =
                isInWarmup
                    ? "${displayCategory.name.capitalize()} ${state.isPaused ? '(warmup paused)' : '(warming up...)'}"
                    : isOnBreak
                    ? "${currentPracticeCategory.name.capitalize()} (break)"
                    : state.isPaused
                    ? "${currentPracticeCategory.name.capitalize()} (paused)"
                    : currentPracticeCategory.name.capitalize();

            return Scaffold(
              appBar: AppBar(
                centerTitle: false,
                title: const Text('Session'),
                actions: [
                  AddManualSessionButton(
                    onManualSessionCreated: (sessionDateTime) {
                      final sessionId =
                          sessionDateTime.millisecondsSinceEpoch ~/ 1000;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => SessionReviewScreen(
                                sessionId: sessionId.toString(),
                                session: null,
                                manualEntry: true,
                                initialDateTime: sessionDateTime,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              drawer: const MainDrawer(),
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final isPortrait =
                      constraints.maxHeight > constraints.maxWidth;
                  if (isPortrait) {
                    // Portrait mode: 4 vertically stacked panes
                    return SafeArea(
                      child: Column(
                        children: [
                          // --- Session Pane (flexible, 36% of available space) ---
                          Expanded(
                            flex: 36,
                            child: Padding(
                              padding: const EdgeInsets.all(.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title
                                  Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // const SizedBox(height: 8),
                                  // Practice Timer Widget
                                  Flexible(
                                    flex: 3,
                                    child: PracticeTimerDisplayWidget(
                                      enabled: true,
                                      showSkipButton:
                                          state.isInWarmup || state.isOnBreak,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ), // Small gap between timer and metronome
                                  // Metronome Widget
                                  Flexible(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: MetronomeWidget(
                                        controller: _metronomeController,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // --- Practice Category Details (flexible, 48% of available space) ---
                          Expanded(
                            flex: 48,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top:
                                    0.0, // Reduced top padding to close gap with metronome
                                bottom: 4.0,
                              ),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child:
                                      state
                                                  .session
                                                  .categories[currentPracticeCategory] !=
                                              null
                                          ? PracticeDetailWidget(
                                            category: currentPracticeCategory,
                                            time:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.time ??
                                                0,
                                            note:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.note ??
                                                '',
                                            songs:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.songs
                                                    ?.keys
                                                    .toList() ??
                                                [],
                                            links:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.links ??
                                                <Link>[],
                                            onTimeChanged:
                                                (val) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionTimeChanged(
                                                        currentPracticeCategory,
                                                        val,
                                                      ),
                                                    ),
                                            onNoteChanged:
                                                (val) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionNoteChanged(
                                                        currentPracticeCategory,
                                                        val,
                                                      ),
                                                    ),
                                            onSongsChanged:
                                                (songs) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionSongsChanged(
                                                        currentPracticeCategory,
                                                        {
                                                          for (var s in songs)
                                                            s: 1,
                                                        },
                                                      ),
                                                    ),
                                            onLinksChanged:
                                                (links) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionLinksChanged(
                                                        currentPracticeCategory,
                                                        links
                                                            .map((l) => l.link)
                                                            .toList(),
                                                      ),
                                                    ),
                                          )
                                          : Center(
                                            child: Text(
                                              'Select a practice mode to begin',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ),
                          // --- Practice Mode Buttons (flexible, 10% of available space) ---
                          Expanded(
                            flex: 10,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    20.0, // Match practice details card total padding (16+16)
                                vertical: 4.0,
                              ),
                              child: _buildPracticeModeButtons(
                                context,
                                displayCategory, // Use displayCategory instead of currentPracticeCategory
                                Orientation.portrait,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Landscape mode: App bar at top, then 3 horizontally stacked panes
                    return SafeArea(
                      child: Row(
                        children: [
                          // --- Practice Mode Buttons (left, 8% width) ---
                          SizedBox(
                            width: constraints.maxWidth * 0.08,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildPracticeModeButtons(
                                context,
                                displayCategory, // Use displayCategory instead of currentPracticeCategory
                                Orientation.landscape,
                              ),
                            ),
                          ),
                          // --- Session Pane (center, 50% width) ---
                          SizedBox(
                            width: constraints.maxWidth * 0.50,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  // Practice Timer Widget
                                  PracticeTimerDisplayWidget(
                                    enabled: true,
                                    showSkipButton:
                                        state.isInWarmup || state.isOnBreak,
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ), // Match spacing inside practice timer
                                  // Metronome Widget
                                  MetronomeWidget(
                                    controller: _metronomeController,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // --- Practice Category Details (right, 35% width) ---
                          SizedBox(
                            width: constraints.maxWidth * 0.35,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child:
                                      state
                                                  .session
                                                  .categories[currentPracticeCategory] !=
                                              null
                                          ? PracticeDetailWidget(
                                            category: currentPracticeCategory,
                                            time:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.time ??
                                                0,
                                            note:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.note ??
                                                '',
                                            songs:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.songs
                                                    ?.keys
                                                    .toList() ??
                                                [],
                                            links:
                                                state
                                                    .session
                                                    .categories[currentPracticeCategory]
                                                    ?.links ??
                                                <Link>[],
                                            onTimeChanged:
                                                (val) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionTimeChanged(
                                                        currentPracticeCategory,
                                                        val,
                                                      ),
                                                    ),
                                            onNoteChanged:
                                                (val) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionNoteChanged(
                                                        currentPracticeCategory,
                                                        val,
                                                      ),
                                                    ),
                                            onSongsChanged:
                                                (songs) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionSongsChanged(
                                                        currentPracticeCategory,
                                                        {
                                                          for (var s in songs)
                                                            s: 1,
                                                        },
                                                      ),
                                                    ),
                                            onLinksChanged:
                                                (links) => context
                                                    .read<SessionBloc>()
                                                    .add(
                                                      SessionLinksChanged(
                                                        currentPracticeCategory,
                                                        links
                                                            .map((l) => l.link)
                                                            .toList(),
                                                      ),
                                                    ),
                                          )
                                          : Center(
                                            child: Text(
                                              'Select a practice mode to begin',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            );
          }
          if (state is SessionCompletedState) {
            // Show session completion dialog
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                final sessionBloc = context.read<SessionBloc>();
                final sessionToRestore = state.session;
                final userProfileProvider = context.read<UserProfileProvider>();
                final dialogContext =
                    context; // Capture context before async operations

                // Determine which dialog to show based on session duration
                final isLongSession =
                    sessionToRestore.duration >= 300; // 5 minutes or more

                String? action;
                if (isLongSession) {
                  // Show dialog with Continue/Save options for sessions >= 5 minutes
                  action = await showDialog<String>(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Session Completed'),
                          content: Text(
                            'Your session is complete!\n\n'
                            'Duration: ${_formatDuration(sessionToRestore.duration)}\n'
                            'Categories: ${_getCompletedCategoriesText(sessionToRestore)}\n\n'
                            'What would you like to do?',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.of(context).pop('continue'),
                              child: const Text('Continue Session'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  () => Navigator.of(context).pop('save'),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                  );
                } else {
                  // Show dialog with Continue/Discard options for sessions < 5 minutes
                  action = await showDialog<String>(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Short Session Completed'),
                          content: Text(
                            'Your session is complete!\n\n'
                            'Duration: ${_formatDuration(sessionToRestore.duration)}\n'
                            'Categories: ${_getCompletedCategoriesText(sessionToRestore)}\n\n'
                            'This session is shorter than 5 minutes. What would you like to do?',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.of(context).pop('discard'),
                              child: const Text('Discard'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  () => Navigator.of(context).pop('continue'),
                              child: const Text('Continue Session'),
                            ),
                          ],
                        ),
                  );
                }

                if (!mounted) return;

                if (action == 'continue') {
                  if (isLongSession) {
                    // User wants to continue the session - restore SessionActive state
                    sessionBloc.add(SessionLoaded(sessionToRestore));
                  } else {
                    // For short sessions, continue means show the normal dialog
                    if (!mounted) return;

                    final secondAction = await showDialog<String>(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Session Completed'),
                            content: Text(
                              'Your session is complete!\n\n'
                              'Duration: ${_formatDuration(sessionToRestore.duration)}\n'
                              'Categories: ${_getCompletedCategoriesText(sessionToRestore)}\n\n'
                              'What would you like to do?',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop('continue'),
                                child: const Text('Continue Session'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => Navigator.of(context).pop('save'),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                    );

                    if (!mounted) return;

                    if (secondAction == 'continue') {
                      // User wants to continue the session - restore SessionActive state
                      sessionBloc.add(SessionLoaded(sessionToRestore));
                    } else if (secondAction == 'save') {
                      // User wants to save - trigger SessionSaved event for proper BLoC architecture
                      sessionBloc.add(SessionSaved(sessionToRestore));
                    }
                  }
                } else if (action == 'save') {
                  // User wants to save - trigger SessionSaved event for proper BLoC architecture
                  sessionBloc.add(SessionSaved(sessionToRestore));
                } else if (action == 'discard') {
                  // User wants to discard the short session
                  AppLoggers.system.info('User chose to discard short session');

                  // Clear any draft session
                  await clearDraftSession(userProfileProvider);

                  if (mounted) {
                    // Navigate back to session screen with new uninitialized session
                    sessionBloc.add(SessionLoaded(null));
                  }
                }
              }
            });
            return Scaffold(
              body: Center(
                child: Text('Session completed. Choose your action...'),
              ),
            );
          }
          if (state is SessionError) {
            return Scaffold(body: Center(child: Text(state.message)));
          }
          return const SizedBox();
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getCompletedCategoriesText(Session session) {
    final categories =
        session.categories.entries
            .where((entry) => entry.value.time > 0)
            .map(
              (entry) =>
                  '${entry.key.name.capitalize()}: ${_formatDuration(entry.value.time)}',
            )
            .toList();

    if (categories.isEmpty) {
      return 'No practice time recorded';
    }

    return categories.join(', ');
  }
}
