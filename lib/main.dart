import 'package:flutter/material.dart';
import 'package:pelican_dev/AppRoutes.dart';

class PelicanExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pelican Example App',
      restorationScopeId: 'root',
      routerDelegate: AppRoutes.router,
      routeInformationParser: AppRoutes.router.parser,
    );
  }
}

void main() {
  AppRoutes.init();
  var app = PelicanExampleApp();
  runApp(app);
}
