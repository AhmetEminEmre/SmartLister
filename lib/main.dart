import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database/firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/readonlylist_screen.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/homepage_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'utilities/notificationmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationManager().initNotification();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

   void initDynamicLinks() async {
    final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      _handleDynamicLink(initialLink.link);
    }

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      _handleDynamicLink(dynamicLinkData.link);
    }).onError((error) {
      print('Failed to handle dynamic link: $error');
    });
  }

  void _handleDynamicLink(Uri link) {
    final listId = link.queryParameters['id'];
    if (listId != null) {
      _navigatorKey.currentState?.pushNamed('/readonlylist', arguments: listId);
    }
  }

  @override
  void initState() {
    super.initState();
    initDynamicLinks();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Flutter Demo',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomePage(uid: snapshot.data!.uid);
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => HomePage(uid: FirebaseAuth.instance.currentUser?.uid ?? ''), //(context) => HomePage(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
        '/readonlylist': (context) => ReadOnlyListScreen(listId: ModalRoute.of(context)?.settings.arguments as String),
      },
    );
  }
}