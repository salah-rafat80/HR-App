import os
import re

def fix_title(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    content = re.sub(r"title:\s*'([^']+)'\.tr\(\)", r"title: Text('\1'.tr())", content)
    content = re.sub(r"title:\s*'([^']+)'(?!.*\.tr)", r"title: Text('\1')", content)
    content = re.sub(r"title:\s*currentReq\.type\.name\.tr\(\)", r"title: Text(currentReq.type.name.tr())", content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                fix_title(os.path.join(root, file))

if __name__ == '__main__':
    main()
