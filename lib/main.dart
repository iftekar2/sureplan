import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/auth/auth_gate.dart';
import 'package:sureplan/notification/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize dotenv
  await dotenv.load(fileName: ".env");

  // initialize supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // initialize firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // initialize notification
  await Notificationservice().initialize();

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.session != null) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getAPNSToken();
        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await supabase
              .from('user_profiles')
              .update({'fcm_token': token})
              .eq('id', event.session!.user.id);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      if (fcmToken != null) {
        await supabase
            .from('user_profiles')
            .update({'fcm_token': fcmToken})
            .eq('id', supabase.auth.currentUser!.id);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("New Event Invitation")));
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        Notificationservice().showNotification(
          id: message.messageId ?? notification.hashCode.toString(),
          title: notification.title ?? "New Event Invitation",
          body: notification.body ?? "You have been invited to a new event!",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthGate());
  }
}
