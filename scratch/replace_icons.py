import os
import re

icon_map = {
    'home': 'home',
    'access_time': 'attendance',
    'clock': 'attendance',
    'calendar_month': 'leave',
    'event_note': 'leave',
    'analytics': 'kpi',
    'track_changes': 'appraisal',
    'account_balance_wallet': 'payroll',
    'school': 'training',
    'forum': 'communication',
    'favorite': 'engagement',
    'account_tree': 'orgChart',
    'group': 'team',
    'people': 'team',
    'admin_panel_settings': 'admin',
    'security': 'admin',
    'person': 'profile',
    'person_outline': 'profile',
    'notifications': 'notifications',
    'arrow_back': 'back',
    'arrow_back_ios': 'back',
    'arrow_left': 'back',
    'check_circle': 'approve',
    'cancel': 'reject',
    'close_circle': 'reject',
    'inbox': 'modules',
    'grid_view': 'modules',
    'category': 'modules',
    'cake': 'engagement',
    'beach_access': 'leave',
    'warning': 'admin',
    'warning_amber_rounded': 'admin',
    'campaign': 'communication',
    'add_task': 'approve',
    'language': 'communication',
    'dark_mode': 'admin',
    'logout': 'back',
    'download': 'payroll',
    'chevron_right': 'back',
    'verified': 'approve',
    'pending': 'attendance',
    'play_arrow': 'approve',
    'add': 'approve',
    'attach_file': 'modules',
    'person_remove': 'reject',
    'person_add': 'profile',
    'check': 'approve',
    'close': 'reject',
    'info': 'modules',
    'error': 'reject',
    'more_vert': 'modules',
    'search': 'modules',
    'filter_list': 'modules',
    'sort': 'modules',
    'edit': 'modules',
    'delete': 'reject',
    'save': 'approve',
    'upload': 'modules',
    'download_done': 'approve',
    'history': 'attendance',
    'settings': 'admin',
    'help': 'communication',
    'send': 'communication',
    'insights': 'kpi',
    'work': 'profile',
    'manage_accounts': 'admin',
    'chevron_left': 'back'
}

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Simple regex to find Icons.something
    def repl(match):
        icon_name = match.group(1)
        if icon_name in icon_map:
            return f"AppIcons.{icon_map[icon_name]}"
        else:
            # Default to a safe icon if not mapped perfectly, or leave it. We should map it.
            return f"AppIcons.modules"

    content = re.sub(r'Icons\.([a-zA-Z0-9_]+)', repl, content)
    
    if content != original_content:
        # Also need to add import for AppIcons if it's missing
        if "import 'package:hr_app_demo/core/theme/app_icons.dart';" not in content and "import '../../../../core/theme/app_icons.dart';" not in content:
            # add it after the first import
            content = re.sub(r'(import .*?;)', r"\1\nimport 'package:hr_app_demo/core/theme/app_icons.dart';", content, count=1)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                replace_in_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
