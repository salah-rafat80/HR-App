import os

replacements = {
    'dashboard_screen.dart': [('Icons.dashboard', 'Iconsax.home_2')],
    'recruitment_screen.dart': [('Icons.add', 'Iconsax.add')],
    'payroll_screen.dart': [('Icons.play_arrow', 'Iconsax.play')],
    'onboarding_screen.dart': [('Icons.check_circle', 'Iconsax.tick_circle'), ('Icons.radio_button_unchecked', 'Iconsax.record')],
    'offboarding_screen.dart': [('Icons.check_circle', 'Iconsax.tick_circle'), ('Icons.radio_button_unchecked', 'Iconsax.record')],
    'approvals_screen.dart': [('Icons.check_circle', 'Iconsax.tick_circle'), ('Icons.cancel', 'Iconsax.close_circle')],
    'login_screen.dart': [
        ('Icons.people', 'Iconsax.people'),
        ('Icons.manage_accounts', 'Iconsax.user_edit'),
        ('Icons.admin_panel_settings', 'Iconsax.security_user'),
        ('Icons.security', 'Iconsax.shield_tick'),
        ('Icons.leaderboard', 'Iconsax.chart_square'),
        ('Icons.admin_panel_settings_outlined', 'Iconsax.security_user')
    ],
    'appraisal_screen.dart': [
        ('Icons.star_border', 'Iconsax.star'),
        ('Icons.calendar_today', 'Iconsax.calendar')
    ]
}

for root, _, files in os.walk('d:/Project-CRM/hr_app_demo/apps/web/lib'):
    for file in files:
        if file in replacements:
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Ensure iconsax_flutter is imported
            if 'package:iconsax_flutter/iconsax_flutter.dart' not in content:
                content = "import 'package:iconsax_flutter/iconsax_flutter.dart';\n" + content
            
            new_content = content
            for old_icon, new_icon in replacements[file]:
                new_content = new_content.replace(old_icon, new_icon)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
