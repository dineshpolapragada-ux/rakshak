import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:share_plus/share_plus.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:shared_preferences/shared_preferences.dart';



void main() {

  runApp(const RakshakApp());

}



class RakshakApp extends StatelessWidget {

  const RakshakApp({super.key});



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Rakshak',

      theme: ThemeData(

        brightness: Brightness.dark,

        useMaterial3: true,

      ),

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

  String locationText = 'Location not acquired';



  // ============================================================

  // VOICE STATE

  // ============================================================



  final stt.SpeechToText speech = stt.SpeechToText();



  bool speechInitialized = false;

  bool voiceListening = false;

  bool voiceCommandHandled = false;



  String voiceStatus = 'Voice test not started';

  String recognizedWords = '';



  // ============================================================

  // TRUSTED CONTACTS

  // ============================================================



  List<Contact> trustedContacts = [];



  bool loadingContacts = false;



  // ============================================================

  // INITIALIZATION

  // ============================================================



  @override

  void initState() {

    super.initState();

    loadTrustedContacts();

  }



  // ============================================================

  // TEST SOS

  // ============================================================



  Future<void> activateTestSOS() async {

    setState(() {

      sosActivated = true;

      gettingLocation = true;

      sosStatus = 'Getting location...';

      locationText = 'Getting location...';

    });



    try {

      final bool serviceEnabled =

          await Geolocator.isLocationServiceEnabled();



      if (!serviceEnabled) {

        setState(() {

          locationText = 'Location services are turned off';

          gettingLocation = false;

          sosStatus = 'Location unavailable';

        });

        return;

      }



      LocationPermission permission =

          await Geolocator.checkPermission();



      if (permission == LocationPermission.denied) {

        permission = await Geolocator.requestPermission();

      }



      if (permission == LocationPermission.denied) {

        setState(() {

          locationText = 'Location permission denied';

          gettingLocation = false;

          sosStatus = 'Location unavailable';

        });

        return;

      }



      if (permission == LocationPermission.deniedForever) {

        setState(() {

          locationText =

              'Location permission permanently denied';

          gettingLocation = false;

          sosStatus = 'Location unavailable';

        });

        return;

      }



      final Position position =

          await Geolocator.getCurrentPosition(

        locationSettings: const LocationSettings(

          accuracy: LocationAccuracy.high,

        ),

      );



      setState(() {

        locationText =

            'Latitude: ${position.latitude}\n'

            'Longitude: ${position.longitude}';



        gettingLocation = false;

        sosStatus = 'Test SOS ready to share';

      });

    } catch (e) {

      setState(() {

        locationText = 'Could not get location';

        gettingLocation = false;

        sosStatus = 'Location unavailable';

      });

    }

  }



  // ============================================================

  // TEST SOS SHARING

  // ============================================================



  Future<void> shareTestSOS() async {

  if (!sosActivated) return;



  String trustedText;



  if (trustedContacts.isEmpty) {

    trustedText = 'No trusted contacts selected.';

  } else {

    trustedText = trustedContacts.map((contact) {

      final name = (contact.displayName ?? '').isEmpty

          ? 'Unnamed contact'

          : contact.displayName ?? 'Unnamed contact';



      final phone = contact.phones.isNotEmpty

          ? contact.phones.first.number

          : 'No phone number';



      return '• $name — $phone';

    }).join('\n');

  }



  final message = '''

🛡️ RAKSHAK — TEST SOS



This is a TEST emergency alert.



📍 Location:

$locationText



👥 Trusted Contacts:

$trustedText



⚠️ TEST MODE — No emergency response required.

''';



  await SharePlus.instance.share(

    ShareParams(

      text: message,

      subject: 'Rakshak Test SOS',

    ),

  );

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

            voiceStatus =

                'Speech recognition unavailable';

          });

        },

      );



      speechInitialized = available;



      if (!available) {

        setState(() {

          voiceStatus =

              'Speech recognition unavailable on this device';

        });

        return;

      }

    }



    setState(() {

      voiceListening = true;

      voiceStatus =

          'Listening for "Rakshak SOS"...';

    });



    await speech.listen(

      listenFor: const Duration(seconds: 10),

      pauseFor: const Duration(seconds: 3),

      onResult: (result) {

        if (!mounted) return;



        final String words =

            result.recognizedWords.toLowerCase();



        setState(() {

          recognizedWords = result.recognizedWords;

        });



        if (words.contains('rakshak sos') &&

            !voiceCommandHandled) {

          voiceCommandHandled = true;



          setState(() {

            voiceStatus =

                'Voice command recognized!';

            voiceListening = false;

          });



          speech.stop();



          activateTestSOS();

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

// TRUSTED CONTACTS — LOAD

// ============================================================



Future<void> loadTrustedContacts() async {

  final prefs = await SharedPreferences.getInstance();



  final List<String> savedIds =

      prefs.getStringList('trusted_contact_ids') ?? [];



  if (savedIds.isEmpty) return;



  final permission =

      await FlutterContacts.permissions.request(

    PermissionType.read,

  );



  if (permission != PermissionStatus.granted) {

    return;

  }



  try {

    final contacts = await FlutterContacts.getAll(

      properties: {ContactProperty.phone},

    );



    final selected = contacts.where(

      (contact) =>

          contact.id != null &&

          savedIds.contains(contact.id),

    ).toList();



    if (!mounted) return;



    setState(() {

      trustedContacts = selected;

    });

  } catch (e) {

    // Ignore loading errors for now.

  }

}



// ============================================================

// TRUSTED CONTACTS — SAVE

// ============================================================



Future<void> saveTrustedContacts() async {

  final prefs = await SharedPreferences.getInstance();



  final ids = trustedContacts

      .map((contact) => contact.id)

      .whereType<String>()

      .toList();



  await prefs.setStringList(

    'trusted_contact_ids',

    ids,

  );

}

// ============================================================

// TRUSTED CONTACTS — SELECT

// ============================================================



Future<void> selectTrustedContacts() async {

  setState(() {

    loadingContacts = true;

  });



  final permission =

      await FlutterContacts.permissions.request(

    PermissionType.read,

  );



  if (permission != PermissionStatus.granted) {

    if (!mounted) return;



    setState(() {

      loadingContacts = false;

    });



    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(

          'Contacts permission is required.',

        ),

      ),

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
    ? const Center(
        child: Text(
          'No contacts found.',
        ),
      )
    : ListView.builder(

                        itemCount: contacts.length,

                        itemBuilder: (context, index) {

                          final contact = contacts[index];



                          final isSelected =

                              trustedContacts.any(

                            (selected) =>

                                selected.id == contact.id,

                          );



                          return CheckboxListTile(

                            value: isSelected,

                            onChanged: (value) {

                              dialogSetState(() {

                                if (value == true) {

                                  if (!trustedContacts.any(

                                    (selected) =>

                                        selected.id ==

                                        contact.id,

                                  )) {

                                    trustedContacts.add(

                                      contact,

                                    );

                                  }

                                } else {

                                  trustedContacts.removeWhere(

                                    (selected) =>

                                        selected.id ==

                                        contact.id,

                                  );

                                }

                              });

                            },

                            title: Text(

                              (contact.displayName ?? '').isEmpty

                                  ? 'Unnamed contact'

                                  : contact.displayName ??

                                      'Unnamed contact',

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



    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(

          'Could not load contacts.',

        ),

      ),

    );

  }

}



// ============================================================

// TRUSTED CONTACTS — REMOVE

// ============================================================



Future<void> removeTrustedContact(Contact contact) async {

  setState(() {

    trustedContacts.removeWhere(

      (item) => item.id == contact.id,

    );

  });



  await saveTrustedContacts();

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

      voiceStatus = 'Voice test not started';

    });

  }



  // ============================================================

  // UI

  // ============================================================



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:

          const Color(0xFF090909),



      appBar: AppBar(

        backgroundColor:

            Colors.transparent,



        title: const Text(

          'RAKSHAK',

          style: TextStyle(

            fontWeight:

                FontWeight.bold,

            letterSpacing: 2,

          ),

        ),



        centerTitle: true,

      ),



      body: SafeArea(

        child: Center(

          child: SingleChildScrollView(

            padding:

                const EdgeInsets.all(24),



            child: Column(

              mainAxisAlignment:

                  MainAxisAlignment.center,



              children: [



                // =================================================

                // HEADER

                // =================================================



                const Text(

                  'EMERGENCY SAFETY',

                  style: TextStyle(

                    fontSize: 14,

                    letterSpacing: 3,

                    color:

                        Colors.white54,

                  ),

                ),



                const SizedBox(

                  height: 35,

                ),



                // =================================================

                // MAIN SOS BUTTON

                // =================================================



                GestureDetector(

                  onLongPress:

                      activateTestSOS,



                  child: Container(

                    width: 220,

                    height: 220,



                    decoration:

                        BoxDecoration(

                      shape:

                          BoxShape.circle,



                      border:

                          Border.all(

                        color:

                            Colors.redAccent,

                        width: 4,

                      ),



                      color: Colors.red

                          .withOpacity(

                        0.15,

                      ),

                    ),



                    child:

                        const Center(

                      child: Text(

                        'HOLD\nFOR SOS',



                        textAlign:

                            TextAlign.center,



                        style:

                            TextStyle(

                          color:

                              Colors.white,

                          fontSize: 25,

                          fontWeight:

                              FontWeight

                                  .bold,

                        ),

                      ),

                    ),

                  ),

                ),



                const SizedBox(

                  height: 30,

                ),



                // =================================================

                // SOS STATUS

                // =================================================



                Text(

                  sosActivated

                      ? '🚨 TEST SOS ACTIVATED'

                      : 'Press and hold the button',



                  textAlign:

                      TextAlign.center,



                  style: TextStyle(

                    fontSize: 17,

                    fontWeight:

                        FontWeight.w600,



                    color: sosActivated

                        ? Colors.redAccent

                        : Colors.white70,

                  ),

                ),

                if (sosActivated) ...[
                  const SizedBox(height: 8),
                  Text(
                    sosStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // LOCATION CARD

                // =================================================



                if (sosActivated)

                  Container(

                    width:

                        double.infinity,



                    padding:

                        const EdgeInsets.all(

                      16,

                    ),



                    decoration:

                        BoxDecoration(

                      borderRadius:

                          BorderRadius

                              .circular(

                        16,

                      ),



                      color: Colors.white

                          .withOpacity(

                        0.06,

                      ),

                    ),



                    child:

                        Column(

                      children: [



                        const Text(

                          '📍 CURRENT LOCATION',



                          style:

                              TextStyle(

                            fontSize: 12,

                            letterSpacing:

                                2,

                            color:

                                Colors.white54,

                          ),

                        ),



                        const SizedBox(

                          height: 10,

                        ),



                        if (gettingLocation)

                          const CircularProgressIndicator(),



                        if (!gettingLocation)

                          Text(

                            locationText,



                            textAlign:

                                TextAlign

                                    .center,



                            style:

                                const TextStyle(

                              fontSize: 15,

                              color:

                                  Colors.white,

                            ),

                          ),

                      ],

                    ),

                  ),



                const SizedBox(

                  height: 20,

                ),



                // =================================================

                // TEST SHARING

                // =================================================



                if (sosActivated) ...[

                  ElevatedButton.icon(

                    onPressed:

                        gettingLocation

                            ? null

                            : shareTestSOS,



                    icon:

                        const Icon(

                      Icons.share,

                    ),



                    label:

                        const Text(

                      'SEND TEST SOS',

                    ),

                  ),



                  const SizedBox(

                    height: 10,

                  ),



                  OutlinedButton(

                    onPressed:

                        resetSOS,



                    child:

                        const Text(

                      'RESET TEST',

                    ),

                  ),



                  const SizedBox(

                    height: 20,

                  ),

                ],



                // =================================================

                // VOICE ACTIVATION

                // =================================================



                const Divider(

                  color:

                      Colors.white12,

                ),



                const SizedBox(

                  height: 18,

                ),



                const Text(

                  'VOICE ACTIVATION TEST',



                  style:

                      TextStyle(

                    fontSize: 12,

                    letterSpacing:

                        2,

                    color:

                        Colors.white54,

                  ),

                ),



                const SizedBox(

                  height: 12,

                ),



                OutlinedButton.icon(

                  onPressed:

                      voiceListening

                          ? stopVoiceTest

                          : startVoiceTest,



                  icon: Icon(

                    voiceListening

                        ? Icons.mic_off

                        : Icons.mic,

                  ),



                  label: Text(

                    voiceListening

                        ? 'STOP VOICE TEST'

                        : 'START VOICE TEST',

                  ),

                ),



                const SizedBox(

                  height: 8,

                ),



                Text(

                  voiceStatus,



                  textAlign:

                      TextAlign.center,



                  style:

                      const TextStyle(

                    color:

                        Colors.white70,

                    fontSize: 13,

                  ),

                ),



                if (recognizedWords

                    .isNotEmpty) ...[

                  const SizedBox(

                    height: 6,

                  ),



                  Text(

                    'Heard: $recognizedWords',



                    textAlign:

                        TextAlign.center,



                    style:

                        const TextStyle(

                      color:

                          Colors.white54,

                      fontSize: 12,

                    ),

                  ),

                ],



                const SizedBox(

                  height: 30,

                ),



                // =================================================

                // TRUSTED CONTACTS

                // =================================================



                const Divider(

                  color:

                      Colors.white12,

                ),



                const SizedBox(

                  height: 18,

                ),



                const Text(

                  'TRUSTED CONTACTS',



                  style:

                      TextStyle(

                    fontSize: 12,

                    letterSpacing:

                        2,

                    color:

                        Colors.white54,

                  ),

                ),



                const SizedBox(

                  height: 8,

                ),



                const Text(

                  'People you choose to receive your Rakshak alerts.',



                  textAlign:

                      TextAlign.center,



                  style:

                      TextStyle(

                    color:

                        Colors.white54,

                    fontSize: 13,

                  ),

                ),



                const SizedBox(

                  height: 14,

                ),



                OutlinedButton.icon(

                  onPressed:

                      loadingContacts

                          ? null

                          : selectTrustedContacts,



                  icon: loadingContacts

                      ? const SizedBox(

                          width: 18,

                          height: 18,

                          child:

                              CircularProgressIndicator(

                            strokeWidth:

                                2,

                          ),

                        )

                      : const Icon(

                          Icons.person_add,

                        ),



                  label: const Text(

                    'ADD TRUSTED CONTACT',

                  ),

                ),



                const SizedBox(

                  height: 12,

                ),



                if (trustedContacts

                    .isEmpty)

                  const Text(

                    'No trusted contacts added yet.',



                    style:

                        TextStyle(

                      color:

                          Colors.white38,

                      fontSize: 13,

                    ),

                  ),



                if (trustedContacts

                    .isNotEmpty)

                  ...trustedContacts

                      .map(

                    (contact) {

                      String phone =

                          'No phone number';



                      if (contact

                          .phones

                          .isNotEmpty) {

                        phone = contact

                            .phones

                            .first

                            .number;

                      }



                      return Card(

                        color: Colors

                            .white

                            .withOpacity(

                          0.05,

                        ),



                        child: ListTile(

                          leading:

                              const CircleAvatar(

                            child:

                                Icon(

                              Icons.person,

                            ),

                          ),



                          title: Text(

  (contact.displayName ?? '').isEmpty

      ? 'Unnamed contact'

      : contact.displayName ?? 'Unnamed contact',

),



                          subtitle:

                              Text(phone),



                          trailing:

                              IconButton(

                            icon:

                                const Icon(

                              Icons

                                  .delete_outline,

                            ),



                            onPressed:

                                () =>

                                    removeTrustedContact(

                              contact,

                            ),

                          ),

                        ),

                      );

                    },

                  ),



                const SizedBox(

                  height: 30,

                ),



                // =================================================

                // VERSION

                // =================================================



                const Text(

                  'RAKSHAK V0.5 • TEST MODE',



                  style:

                      TextStyle(

                    fontSize: 12,

                    color:

                        Colors.white38,

                    letterSpacing:

                        1,

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