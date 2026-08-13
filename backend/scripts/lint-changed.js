const { execSync } = require('child_process');

try {
  const stagedFiles = execSync('git diff --name-only --cached -- "*.ts"', {
    encoding: 'utf8',
  })
    .split('\n')
    .map((f) => f.trim())
    .filter(Boolean);

  if (stagedFiles.length === 0) {
    console.log('No staged TypeScript files to lint.');
    process.exit(0);
  }

  console.log(`Linting ${stagedFiles.length} staged file(s):`);
  stagedFiles.forEach((f) => console.log(`  - ${f}`));

  execSync(`npx eslint ${stagedFiles.join(' ')}`, { stdio: 'inherit' });
  console.log('✅ Staged files passed ESLint checks.');
  process.exit(0);
} catch (error) {
  console.error('❌ Blocking Changed-Files Lint Gate: Staged files contain ESLint errors.');
  process.exit(1);
}
