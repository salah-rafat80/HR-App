import os
import re

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                original = content
                if 'appBar: AppBar(' in content:
                    content = content.replace('appBar: AppBar(', 'appBar: AppCustomBar(')
                    content = re.sub(r'(Scaffold\(\s*)', r'\1extendBodyBehindAppBar: true,\n        ', content)
                    if "import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';" not in content and "import '../../../../core/widgets/app_custom_bar.dart';" not in content:
                        content = re.sub(r'(import .*?;)', r"\1\nimport 'package:hr_app_demo/core/widgets/app_custom_bar.dart';", content, count=1)
                    
                if content != original:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {filepath}")

if __name__ == '__main__':
    main()
