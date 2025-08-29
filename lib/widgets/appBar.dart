import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quantum_dashboard/utils/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 50,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      elevation: 5.0,
      shadowColor: Theme.of(context).shadowColor,
      leading: IconButton(
        icon: SvgPicture.asset(
          AppAssets.menuIcon,
          color: Colors.black,
          width: 24,
          height: 24,
        ),
        color: Colors.black,
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),

      centerTitle: true,
      title: Image.asset(AppAssets.quantumLogoH, height: 35),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
