import os
import re

for root, _, files in os.walk('d:/Project-CRM/hr_app_demo/apps/web/lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            new_content = new_content.replace('.withOpacity(', '.withValues(alpha: ')
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
