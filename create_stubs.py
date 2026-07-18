import os

files = {
    'auth/presentation/pages/login_screen.dart': 'LoginScreen',
    'shell/presentation/pages/desktop_shell.dart': 'DesktopShell',
    'approvals/presentation/pages/approvals_screen.dart': 'ApprovalsScreen',
    'team_kpi/presentation/pages/team_kpi_screen.dart': 'TeamKpiScreen',
    'payroll/presentation/pages/payroll_screen.dart': 'PayrollScreen',
    'recruitment/presentation/pages/recruitment_screen.dart': 'RecruitmentScreen',
    'onboarding/presentation/pages/onboarding_screen.dart': 'OnboardingScreen',
    'offboarding/presentation/pages/offboarding_screen.dart': 'OffboardingScreen',
    'system_config/presentation/pages/system_config_screen.dart': 'SystemConfigScreen',
    'appraisal/presentation/pages/appraisal_screen.dart': 'AppraisalScreen',
    'executive/presentation/pages/executive_screen.dart': 'ExecutiveScreen',
    'shell/presentation/pages/dashboard_screen.dart': 'DashboardScreen',
}

template = '''import 'package:flutter/material.dart';

class {className} extends StatelessWidget {{
  const {className}({{super.key}});

  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      body: Center(
        child: Text('{className}'),
      ),
    );
  }}
}}
'''

template_shell = '''import 'package:flutter/material.dart';

class DesktopShell extends StatelessWidget {{
  final Widget child;
  const DesktopShell({{super.key, required this.child}});

  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.grey[200],
            child: const Center(child: Text('Sidebar')),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }}
}}
'''

for path, className in files.items():
    full_path = os.path.join('d:/Project-CRM/hr_app_demo/apps/web/lib/features', path)
    with open(full_path, 'w', encoding='utf-8') as f:
        if className == 'DesktopShell':
            f.write(template_shell)
        else:
            f.write(template.format(className=className))

print("Created all stub files")
