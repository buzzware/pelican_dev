import 'package:flutter/material.dart';

import 'SettingsCarTab.dart';

class SettingsPage extends StatelessWidget {

  static const TAB_NAMES = ['Transit','Car','Bike'];
  static const TAB_ICONS = [Icons.directions_transit,Icons.directions_car,Icons.directions_bike];

  Map<String, String?> params;

  SettingsPage(this.params);

  @override
  Widget build(BuildContext context) {

    var tabIndex = params['vehicle_tab']==null ? 0 : TAB_NAMES.indexOf(params['vehicle_tab']!);
    if (tabIndex<0)
      tabIndex = 0;

    return DefaultTabController(
      length: 3,
      initialIndex: tabIndex,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs:  TAB_ICONS.map((n) => Tab(icon: Icon(n))).toList(),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              Container(color: Colors.blue),
              SettingsCarTab(section_tab: params['section_tab']),
              Container(color: Colors.yellow),
            ],
          ),
        ),
      ),
    );
  }
}
