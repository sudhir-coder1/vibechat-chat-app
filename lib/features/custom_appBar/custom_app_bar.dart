import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  final String title1;
  final String? name;
  final IconData? actionicon;
  final VoidCallback?  onTap;
  final int badgeCount;


  const CustomAppBar({
    super.key,
    required this.title1,
    this.name,
    this.actionicon, 
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 70,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,

      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEC4DFF),
              Color(0xFF8A4DFF),
              Color(0xFF3D8BFF),
            ],
          ),
        ),
      ),

      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title1,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            name ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (actionicon != null)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: onTap, 
                icon: Icon(actionicon, color: Colors.white, size: 28,)
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 8,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}