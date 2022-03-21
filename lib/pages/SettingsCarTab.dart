import 'package:flutter/material.dart';
import 'package:collection/src/iterable_extensions.dart';

import '../AppRoutes.dart';

class SettingsCarTab extends StatelessWidget {

  static const TAB_NAMES = ['Engine','Appearance','Comfort'];

  String? section_tab;

  SettingsCarTab({Key? key, this.section_tab}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    var tabBar = TabBar(
      tabs:  TAB_NAMES.map((n) => Tab(text: n)).toList(),
      onTap: (value) => AppRoutes.router.replaceParam('section_tab',TAB_NAMES[value]),
    );
    var tabBarView = TabBarView(
      // physics: BouncingScrollPhysics(),
      // dragStartBehavior: DragStartBehavior.down,
      children: [
        Center(child: Text(TAB_NAMES[0])),
        Center(child: Text(TAB_NAMES[1])),
        Center(child: Text(TAB_NAMES[2]))
      ],
    );

    var tabIndex = section_tab==null ? 0 : TAB_NAMES.indexOf(section_tab!);
    if (tabIndex<0)
      tabIndex = 0;

    return DefaultTabController(
      length: 3,
      initialIndex: tabIndex,
      child: Scaffold(
        appBar: AppBar(
          bottom: tabBar,
          // title: const Text('Woolha.com Flutter Tutorial'),
          // backgroundColor: Colors.teal,
        ),
        body: tabBarView,
      ),
    );
  }
}
