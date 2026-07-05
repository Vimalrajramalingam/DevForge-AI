import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/core/theme.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = authProvider.user?.fullName ?? "Developer";
    final userEmail = authProvider.user?.email ?? "dev@example.com";

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "DevForge AI",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          const SizedBox(height: 16),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: "Dashboard",
                  index: 0,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  title: "Project History",
                  index: 1,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  title: "Progress Tracker",
                  index: 2,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.health_and_safety_outlined,
                  activeIcon: Icons.health_and_safety,
                  title: "Health Analyzer",
                  index: 3,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.tips_and_updates_outlined,
                  activeIcon: Icons.tips_and_updates,
                  title: "AI Improvements",
                  index: 4,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  title: "Profile",
                  index: 5,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  title: "Settings",
                  index: 6,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  icon: Icons.info_outline,
                  activeIcon: Icons.info,
                  title: "About",
                  index: 7,
                ),
              ],
            ),
          ),
          
          // User profile & logout
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "D",
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xff9ca3af) : const Color(0xff64748b),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, size: 18),
                  onPressed: () {
                    authProvider.logout();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  tooltip: "Logout",
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => onDestinationSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? AppTheme.primaryBlue.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? AppTheme.primaryBlue 
                  : (isDark ? const Color(0xff9ca3af) : const Color(0xff64748b)),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? AppTheme.primaryBlue 
                    : (isDark ? Colors.white : const Color(0xff1e293b)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ResponsiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const ResponsiveNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (width > 800) {
      // Large screens: Side navigation + main content
      return Scaffold(
        body: Row(
          children: [
            SidebarWidget(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            Expanded(child: child),
          ],
        ),
      );
    } else {
      // Small screens: Mobile Bottom nav bar
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: isDark ? const Color(0xff9ca3af) : const Color(0xff64748b),
          elevation: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: "Settings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: "About",
            ),
          ],
        ),
      );
    }
  }
}
