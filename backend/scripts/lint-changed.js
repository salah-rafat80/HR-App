const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Legacy baseline files pending full refactoring in future commits
const LEGACY_EXCLUDED_FILES = [
  'src/leave/leave.service.ts',
  'src/appraisal/appraisal.service.ts',
  'src/payroll/payroll.service.ts',
  'src/attendance/attendance.service.ts',
  'src/notifications/notification.service.ts',
];

try {
  let diffTarget = process.argv[2] || '--cached';

  let rawFiles = '';
  try {
    rawFiles = execSync(`git diff --name-only ${diffTarget} -- "*.ts"`, {
      encoding: 'utf8',
    });
  } catch (e) {
    // Fallback if target revision not found
    try {
      rawFiles = execSync('git diff --name-only HEAD~1..HEAD -- "*.ts"', {
        encoding: 'utf8',
      });
    } catch (e2) {
      rawFiles = execSync('git diff --name-only --cached -- "*.ts"', {
        encoding: 'utf8',
      });
    }
  }

  const fileList = rawFiles
    .split('\n')
    .map((f) => f.trim())
    .filter(Boolean);

  const currentDir = process.cwd();
  const repoRoot = execSync('git rev-parse --show-toplevel', {
    encoding: 'utf8',
  }).trim();

  const stagedFiles = fileList
    .map((f) => path.relative(currentDir, path.join(repoRoot, f)))
    .filter(
      (f) =>
        fs.existsSync(f) &&
        !LEGACY_EXCLUDED_FILES.some((legacy) => f.replaceAll('\\', '/').endsWith(legacy)),
    );

  if (stagedFiles.length === 0) {
    console.log('No new or refactored changed TypeScript files to lint.');
    process.exit(0);
  }

  console.log(`Linting ${stagedFiles.length} refactored changed file(s):`);
  stagedFiles.forEach((f) => console.log(`  - ${f}`));

  execSync(`npx eslint ${stagedFiles.map((f) => `"${f}"`).join(' ')}`, {
    stdio: 'inherit',
  });
  console.log('✅ Changed refactored files passed ESLint checks.');
  process.exit(0);
} catch (error) {
  console.error(
    '❌ Blocking Changed-Files Lint Gate: Changed files contain ESLint errors.',
  );
  process.exit(1);
}
