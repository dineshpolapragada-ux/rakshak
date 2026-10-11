import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:rakshak/background/rakshak_foreground_service.dart';

import 'background/rakshak_event_router.dart';
import 'background/rakshak_safety_event.dart';
import 'background/rakshak_safety_event_handler.dart';
import 'safety/location_snapshot.dart';
import 'safety/alert_recipient.dart';
import 'safety/communication_service.dart';
import 'safety/alert_payload.dart';
import 'safety/emergency_countdown.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'rakshak_foreground',
      channelName: 'Rakshak Emergency Service',
channelDescription: 'Rakshak emergency safety service',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );

  FlutterForegroundTask.initCommunicationPort();

  runApp(const RakshakApp());
}

class RakshakApp extends StatelessWidget {
  const RakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Rakshak',

      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),

      home: const RakshakHome(),
    );
  }
}

class RakshakHome extends StatefulWidget {
  const RakshakHome({super.key});

  @override
  State<RakshakHome> createState() => _RakshakHomeState();
}

class _RakshakHomeState extends State<RakshakHome> {
  // ============================================================

  // SOS STATE

  // ============================================================

  bool sosActivated = false;

  bool gettingLocation = false;

  String sosStatus = 'Ready';
  RakshakEmergencyCountdown? _emergencyCountdown;
int _sosCountdown = 0;
bool _sosCountdownActive = false;
Completer<bool>? _sosCountdownCompleter;

  String locationText = 'Location not acquired';
  Position? latestSafetyPosition;

  // ============================================================

  // VOICE STATE

  // ============================================================

  final stt.SpeechToText speech = stt.SpeechToText();

  bool speechInitialized = false;

  bool voiceListening = false;

  bool voiceCommandHandled = false;

  String voiceStatus = 'Voice activation ready';

  String recognizedWords = '';

  // ============================================================

  // TRUSTED CONTACTS

  // ============================================================

  List<Contact> trustedContacts = [];

  bool loadingContacts = false;
  final RakshakCommunicationService communicationService =
    const RakshakCommunicationService();

  void _handleForegroundTaskData(Object data) {
  debugPrint('🔥🔥🔥 RAKSHAK MAIN APP RECEIVED DATA: $data');
  debugPrint('🔥🔥🔥 DATA TYPE: ${data.runtimeType}');

  // Handle background SOS requests BEFORE sending them
  // directly into the production safety controller.
  if (data is Map && data['type'] == 'sos_trigger') {
    debugPrint('🚨 VOICE SOS REQUEST RECEIVED BY MAIN APP');

    if (!mounted) return;

    setState(() {
      voiceStatus = 'Voice SOS detected — countdown started';
    });

    // Start the same 10-second safety countdown used
    // by the physical SOS button.
    activateSOS();
    return;
  }

  // Normal background events.
  RakshakEventRouter.handle(data);

  if (!mounted) return;

  if (data is Map && data['type'] == 'test_safety_event') {
    setState(() {
      voiceStatus = 'Background safety event received!';
    });

    debugPrint('🚨 TEST SAFETY EVENT RECEIVED');
    return;
  }

  if (data is Map && data['type'] == 'heartbeat') {
    setState(() {
      voiceStatus = 'Background heartbeat received!';
    });
  }
}

  // ============================================================

  // INITIALIZATION

  // ============================================================

  @override
  void initState() {
    super.initState();

    FlutterForegroundTask.addTaskDataCallback(_handleForegroundTaskData);

    loadTrustedContacts();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_handleForegroundTaskData);

    super.dispose();
  }
  // =================================================
// PRODUCTION SOS
// =================================================

Future<void> activateSOS() async {
  debugPrint('🚨 RAKSHAK: SOS ACTIVATED');

  _emergencyCountdown?.dispose();

  setState(() {
    sosActivated = true;
    _sosCountdown = 10;
    _sosCountdownActive = true;
    sosStatus = 'Emergency activation started';
  });

  final countdownCompleted = Completer<bool>();
  _sosCountdownCompleter = countdownCompleted;

  _emergencyCountdown = RakshakEmergencyCountdown(
    seconds: 10,
    onTick: (remaining) {
      if (!mounted) return;

      setState(() {
        _sosCountdown = remaining;
      });
    },
    onExpired: () {
      if (!countdownCompleted.isCompleted) {
        countdownCompleted.complete(true);
      }
    },
  );

  _emergencyCountdown!.start();

  final countdownFinished = await countdownCompleted.future;

  if (!countdownFinished || !mounted) {
    return;
  }

  setState(() {
    _sosCountdownActive = false;
  });

  try {
    // Start the safety lifecycle through the existing controller.

    final event = RakshakSafetyEvent(
  type: 'sos_trigger',
  message: 'SOS activated by user',
  timestamp: DateTime.now(),
  source: 'sos_button',
);

    RakshakEventRouter.handle(event);

    // Acquire the current location.
    setState(() {
      gettingLocation = true;
      sosStatus = 'Getting location...';
    });

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    latestSafetyPosition = position;

    final locationSnapshot = RakshakLocationSnapshot(
  latitude: position.latitude,
  longitude: position.longitude,
  accuracy: position.accuracy,
  capturedAt: DateTime.now(),
);

    setState(() {
      locationText =
          '${position.latitude}, ${position.longitude}';
      gettingLocation = false;
      sosStatus = 'Emergency location acquired';
    });

    debugPrint('📍 RAKSHAK SOS LOCATION: $locationSnapshot');
   final trustedContactIds = trustedContacts
        .where((contact) =>
            contact.phones.isNotEmpty &&
            contact.phones.any(
              (phone) => phone.number.trim().isNotEmpty,
            ))
        .map((contact) => contact.id)
        .whereType<String>()
        .toList();
  final alertRecipients = trustedContacts
    .where((contact) =>
        contact.id != null &&
        contact.phones.isNotEmpty &&
        contact.phones.any(
          (phone) => phone.number.trim().isNotEmpty,
        ))
    .map((contact) {
      final phone = contact.phones
          .firstWhere(
            (phone) => phone.number.trim().isNotEmpty,
          )
          .number
          .trim();

      final displayName = (contact.displayName ?? '').trim();

      return RakshakAlertRecipient(
        contactId: contact.id!,
        displayName: displayName.isEmpty
            ? 'Trusted Contact'
            : displayName,
        phoneNumber: phone,
      );
    })
    .toList();

debugPrint(
  '👥 RAKSHAK ALERT RECIPIENTS: ${alertRecipients.length}',
);

    debugPrint(
      '👥 RAKSHAK VALID TRUSTED CONTACTS: ${trustedContactIds.length}',
    );

final productionAction =
    RakshakSafetyEventHandler.controller.prepareProductionAlert(
  location: locationSnapshot,
  trustedContactsAvailable: trustedContactIds.isNotEmpty,
  trustedContactIds: trustedContactIds,
recipients: alertRecipients,
);
if (productionAction != null) {
  final dispatchResult =
      RakshakSafetyEventHandler.controller.productionAlertDispatcher
          .dispatch(productionAction);

  debugPrint(
    '📬 RAKSHAK PRODUCTION DISPATCH RESULT: $dispatchResult',
  );

  final payload = productionAction.payload;

  if (payload != null && payload.recipients.isNotEmpty) {
    await reviewSmsAlert(payload);
  } else {
    debugPrint(
      '⚠️ RAKSHAK: No valid SMS recipients available.',
    );
  }
}
 else {
  debugPrint(
    '⚠️ RAKSHAK: Production alert action was not created.',
  );
}

    // Production safety gate.
    //
    // Contact notification/calling should only happen after
    // the production dispatch layer is explicitly enabled.
    debugPrint(
      '🛡️ RAKSHAK: Production dispatch gate reached.',
    );

    // TODO: connect the verified production alert dispatcher here.
    //
    // Do NOT silently send messages/calls until that dispatcher
    // has proper permissions, contact validation, failure handling,
    // and an explicit production configuration.

    setState(() {
      sosStatus = 'SOS active — emergency workflow ready';
    });
  } catch (e) {
    debugPrint('❌ RAKSHAK SOS ERROR: $e');

    setState(() {
      gettingLocation = false;
      sosStatus = 'Unable to acquire emergency location';
    });
  }
}
Future<void> reviewSmsAlert(
  RakshakAlertPayload payload,
) async {
  if (!mounted) return;

  final message = communicationService.buildAlertMessage(payload);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Review SOS Alert'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The following trusted contacts are configured:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...payload.recipients.map(
                  (recipient) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person),
                    title: Text(recipient.displayName),
                    subtitle: Text(recipient.phoneNumber),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rakshak will open your phone\'s SMS composer so you can review and send the alert.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONTINUE'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !mounted) return;

  if (payload.recipients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No trusted contact is available for SMS.'),
      ),
    );
    return;
  }

  final firstRecipient = payload.recipients.first;

  final opened = await communicationService.openSmsComposer(
    phoneNumber: firstRecipient.phoneNumber,
    message: message,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        opened
            ? 'SMS composer opened for ${firstRecipient.displayName}.'
            : 'Could not open the SMS composer.',
      ),
    ),
  );
}


  

  Future<void> startRakshakService() async {
    final permission =
        await FlutterForegroundTask.requestNotificationPermission();

    if (permission != NotificationPermission.granted) {
      debugPrint('Notification permission not granted.');
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Rakshak Emergency Service',
notificationText: 'Rakshak safety service is active.',
      callback: startCallback,
    );
  }

  Future<void> stopRakshakService() async {
    await FlutterForegroundTask.stopService();
  }

  

  // ============================================================

  // VOICE TEST

  // ============================================================

  Future<void> startVoiceTest() async {
    if (voiceListening) return;

    voiceCommandHandled = false;

    setState(() {
      voiceStatus = 'Preparing microphone...';

      recognizedWords = '';
    });

    if (!speechInitialized) {
      final bool available = await speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            voiceListening = status == 'listening';
          });
        },

        onError: (error) {
          if (!mounted) return;

          setState(() {
            voiceListening = false;

            voiceStatus = 'Speech recognition unavailable';
          });
        },
      );

      speechInitialized = available;

      if (!available) {
        setState(() {
          voiceStatus = 'Speech recognition unavailable on this device';
        });

        return;
      }
    }

    setState(() {
      voiceListening = true;

      voiceStatus = 'Listening for "Rakshak SOS"...';
    });

    await speech.listen(
  listenFor: const Duration(seconds: 10),
  pauseFor: const Duration(seconds: 3),

  onResult: (result) {
    if (!mounted) return;

    final String words = result.recognizedWords.toLowerCase().trim();

    setState(() {
      recognizedWords = result.recognizedWords;
    });

    if (words.contains('rakshak sos') && !voiceCommandHandled) {
      voiceCommandHandled = true;

      setState(() {
        voiceStatus = 'Voice command recognized!';
        voiceListening = false;
      });

      speech.stop();

      debugPrint(
        '🎙️🚨 RAKSHAK: Voice SOS phrase detected',
      );

      // Start the same 10-second SOS countdown used
// by the physical SOS button.
activateSOS();
    }
  },
);
  }

  Future<void> stopVoiceTest() async {
    await speech.stop();

    if (!mounted) return;

    setState(() {
      voiceListening = false;

      voiceStatus = 'Voice test stopped';
    });
  }

  // ============================================================

  // TRUSTED CONTACTS Ã¢â‚¬â€ LOAD

  // ============================================================

  Future<void> loadTrustedContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> savedIds =
        prefs.getStringList('trusted_contact_ids') ?? [];

    if (savedIds.isEmpty) return;

    final permission = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (permission != PermissionStatus.granted) {
      return;
    }

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      final selected = contacts
          .where(
            (contact) => contact.id != null && savedIds.contains(contact.id),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        trustedContacts = selected;
      });
    } catch (e) {
      // Ignore loading errors for now.
    }
  }

  // ============================================================

  // TRUSTED CONTACTS Ã¢â‚¬â€ SAVE

  // ============================================================

  Future<void> saveTrustedContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final ids = trustedContacts
        .map((contact) => contact.id)
        .whereType<String>()
        .toList();

    await prefs.setStringList('trusted_contact_ids', ids);
  }

  // ============================================================

  // TRUSTED CONTACTS Ã¢â‚¬â€ SELECT

  // ============================================================

  Future<void> selectTrustedContacts() async {
    setState(() {
      loadingContacts = true;
    });

    final permission = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (permission != PermissionStatus.granted) {
      if (!mounted) return;

      setState(() {
        loadingContacts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission is required.')),
      );

      return;
    }

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      if (!mounted) return;

      setState(() {
        loadingContacts = false;
      });

      await showDialog(
        context: context,

        builder: (context) {
          return StatefulBuilder(
            builder: (context, dialogSetState) {
              return AlertDialog(
                title: const Text('Select Trusted Contacts'),

                content: SizedBox(
                  width: double.maxFinite,

                  height: 450,

                  child: contacts.isEmpty
                      ? const Center(child: Text('No contacts found.'))
                      : ListView.builder(
                          itemCount: contacts.length,

                          itemBuilder: (context, index) {
                            final contact = contacts[index];

                            final isSelected = trustedContacts.any(
                              (selected) => selected.id == contact.id,
                            );

                            return CheckboxListTile(
                              value: isSelected,

                              onChanged: (value) {
                                dialogSetState(() {
                                  if (value == true) {
                                    if (!trustedContacts.any(
                                      (selected) => selected.id == contact.id,
                                    )) {
                                      trustedContacts.add(contact);
                                    }
                                  } else {
                                    trustedContacts.removeWhere(
                                      (selected) => selected.id == contact.id,
                                    );
                                  }
                                });
                              },

                              title: Text(
                                (contact.displayName ?? '').isEmpty
                                    ? 'Unnamed contact'
                                    : contact.displayName ?? 'Unnamed contact',
                              ),

                              subtitle: Text(
                                contact.phones.isNotEmpty
                                    ? contact.phones.first.number
                                    : 'No phone number',
                              ),
                            );
                          },
                        ),
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text('CANCEL'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      await saveTrustedContacts();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      if (mounted) {
                        setState(() {});
                      }
                    },

                    child: const Text('DONE'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingContacts = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load contacts.')));
    }
  }

  // ============================================================

  // TRUSTED CONTACTS Ã¢â‚¬â€ REMOVE

  // ============================================================

  Future<void> removeTrustedContact(Contact contact) async {
    setState(() {
      trustedContacts.removeWhere((item) => item.id == contact.id);
    });

    await saveTrustedContacts();
  }
  void _cancelSOSCountdown() {
  _emergencyCountdown?.cancel();

  if (_sosCountdownCompleter != null &&
      !_sosCountdownCompleter!.isCompleted) {
    _sosCountdownCompleter!.complete(false);
  }

  _sosCountdownCompleter = null;

  if (!mounted) return;

  setState(() {
    _sosCountdownActive = false;
    _sosCountdown = 0;
    sosActivated = false;
    gettingLocation = false;
    sosStatus = 'SOS cancelled';
  });

  debugPrint('🛑 RAKSHAK: SOS countdown cancelled by user');
}

  // ============================================================

  // RESET

  // ============================================================

  void resetSOS() {
    setState(() {
      sosActivated = false;

      gettingLocation = false;

      sosStatus = 'Ready';

      locationText = 'Location not acquired';

      recognizedWords = '';

      voiceStatus = 'Voice activation ready';
    });
  }

  // ============================================================

  // UI

  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: const Text(
          'RAKSHAK',

          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // =================================================

                // HEADER

                // =================================================
                const Text(
                  'EMERGENCY SAFETY',

                  style: TextStyle(
                    fontSize: 14,

                    letterSpacing: 3,

                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 35),

                // =================================================

                // MAIN SOS BUTTON

                // =================================================
                GestureDetector(
                  onLongPress: activateSOS,

                  child: Container(
                    width: 220,

                    height: 220,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      border: Border.all(color: Colors.redAccent, width: 4),

                      color: Colors.red.withOpacity(0.15),
                    ),

                    child: const Center(
                      child: Text(
                        'HOLD\nFOR SOS',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 25,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 30),

                // =================================================

                // SOS STATUS

                // =================================================
                Text(
                  sosActivated
                      ? '🚨 SOS ACTIVATED'
                      : 'Press and hold the button',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 17,

                    fontWeight: FontWeight.w600,

                    color: sosActivated ? Colors.redAccent : Colors.white70,
                  ),
                ),

                if (sosActivated) ...[
                  const SizedBox(height: 8),
                  Text(
                    sosStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 20),
              if (_sosCountdownActive) ...[
  const SizedBox(height: 12),

  Text(
    'SOS continues in $_sosCountdown',
    style: const TextStyle(
      color: Colors.orangeAccent,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 12),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _cancelSOSCountdown,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text(
        'CANCEL SOS',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
],

                // =================================================
                // LOCATION CARD

                // =================================================
                if (sosActivated)
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),

                      color: Colors.white.withOpacity(0.06),
                    ),

                    child: Column(
                      children: [
                        const Text(
                          'Ã°Å¸â€œÂ CURRENT LOCATION',

                          style: TextStyle(
                            fontSize: 12,

                            letterSpacing: 2,

                            color: Colors.white54,
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (gettingLocation) const CircularProgressIndicator(),

                        if (!gettingLocation)
                          Text(
                            locationText,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              fontSize: 15,

                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                



                // =================================================
                // TRUSTED CONTACTS
                // =================================================
                const Divider(color: Colors.white12),

                const SizedBox(height: 18),

                const Text(
                  'TRUSTED CONTACTS',

                  style: TextStyle(
                    fontSize: 12,

                    letterSpacing: 2,

                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'People you choose to receive your Rakshak alerts.',

                  textAlign: TextAlign.center,

                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),

                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: loadingContacts ? null : selectTrustedContacts,

                  icon: loadingContacts
                      ? const SizedBox(
                          width: 18,

                          height: 18,

                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),

                  label: const Text('ADD TRUSTED CONTACT'),
                ),

                const SizedBox(height: 12),

                if (trustedContacts.isEmpty)
                  const Text(
                    'No trusted contacts added yet.',

                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),

                if (trustedContacts.isNotEmpty)
                  ...trustedContacts.map((contact) {
                    String phone = 'No phone number';

                    if (contact.phones.isNotEmpty) {
                      phone = contact.phones.first.number;
                    }

                    return Card(
                      color: Colors.white.withOpacity(0.05),

                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),

                        title: Text(
                          (contact.displayName ?? '').isEmpty
                              ? 'Unnamed contact'
                              : contact.displayName ?? 'Unnamed contact',
                        ),

                        subtitle: Text(phone),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),

                          onPressed: () => removeTrustedContact(contact),
                        ),
                      ),
                    );
                  }),
                const Divider(color: Colors.white12),

const SizedBox(height: 18),

const Text(
  'VOICE SOS TEST',

  style: TextStyle(
    fontSize: 12,
    letterSpacing: 2,
    color: Colors.white54,
  ),
),
const Divider(color: Colors.white12),
const SizedBox(height: 18),

const Text(
  'BACKGROUND SERVICE',
  style: TextStyle(
    fontSize: 12,
    letterSpacing: 2,
    color: Colors.white54,
  ),
),

const SizedBox(height: 8),

const Text(
  'Run Rakshak safety service in the background.',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: Colors.white54,
    fontSize: 13,
  ),
),

const SizedBox(height: 14),

OutlinedButton.icon(
  onPressed: startRakshakService,
  icon: const Icon(Icons.security),
  label: const Text('START RAKSHAK SERVICE'),
),

const SizedBox(height: 30),

const SizedBox(height: 8),

Text(
  voiceStatus,
  textAlign: TextAlign.center,
  style: const TextStyle(
    color: Colors.white54,
    fontSize: 13,
  ),
),

const SizedBox(height: 14),

OutlinedButton.icon(
  onPressed: voiceListening ? stopVoiceTest : startVoiceTest,
  icon: Icon(
    voiceListening ? Icons.mic_off : Icons.mic,
  ),
  label: Text(
    voiceListening
        ? 'STOP VOICE TEST'
        : 'START VOICE TEST',
  ),
),

if (recognizedWords.isNotEmpty) ...[
  const SizedBox(height: 10),
  Text(
    'Heard: $recognizedWords',
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 12,
    ),
  ),
],

const SizedBox(height: 30),

                const SizedBox(height: 30),

                // =================================================

                // VERSION

                // =================================================
                const Text(
                  'RAKSHAK V0.5',

                  style: TextStyle(
                    fontSize: 12,

                    color: Colors.white38,

                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}









