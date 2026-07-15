import os
import re

for root, _, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'):
            continue
        filepath = os.path.join(root, file)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        modified = False
        
        # We look for something like:
        # Chip(label: Text('pending'.tr(), style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.warning)
        # or similar. It's safer to just replace it manually in a few files using python regex.
        # Actually, let's just find and replace in the known files.
        
        # A simple regex for pending chip:
        # Chip(label: Text(\w+, style: ...), backgroundColor: AppColors.warning)
        # We can just replace Chip(label: Text(VAR, ...), backgroundColor: AppColors.warning) with PulsingPendingChip(label: VAR)
        
        pattern = r"Chip\(\s*label:\s*Text\(([^,]+)(?:,\s*style:\s*[^)]+\))?\),\s*backgroundColor:\s*AppColors\.warning\s*\)"
        
        def replacer(match):
            return f"PulsingPendingChip(label: {match.group(1)})"
        
        new_content = re.sub(pattern, replacer, content)
        if new_content != content:
            content = new_content
            modified = True
            
            if 'pulsing_pending_chip.dart' not in content:
                # Add import
                matches = list(re.finditer(r"import\s+['\"].*?['\"];\n", content))
                if matches:
                    last_match = matches[-1]
                    rel_path = os.path.relpath('lib/core/widgets/pulsing_pending_chip.dart', start=os.path.dirname(filepath))
                    rel_path = rel_path.replace('\\', '/')
                    import_stmt = f"import '{rel_path}';\n"
                    content = content[:last_match.end()] + import_stmt + content[last_match.end():]

        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Modified {filepath}')
