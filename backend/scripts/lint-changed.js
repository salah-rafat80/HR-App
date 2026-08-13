const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');

function changedTypescriptFiles(diffTarget) {
  return execFileSync('git', ['diff', '--name-only', diffTarget, '--', '*.ts'], {
    encoding: 'utf8',
  })
    .split('\n')
    .map((file) => file.trim())
    .filter(Boolean);
}

try {
  const requestedRange = process.argv[2] || '--cached';
  let fileList;

  try {
    fileList = changedTypescriptFiles(requestedRange);
  } catch {
    fileList = changedTypescriptFiles('HEAD~1..HEAD');
  }

  const repoRoot = execFileSync('git', ['rev-parse', '--show-toplevel'], {
    encoding: 'utf8',
  }).trim();
  const currentDir = process.cwd();
  const files = fileList
    .map((file) => path.relative(currentDir, path.join(repoRoot, file)))
    .filter((file) => fs.existsSync(file));

  if (files.length === 0) {
    console.log('No changed TypeScript files in the selected commit range.');
    process.exit(0);
  }

  console.log(`Linting ${files.length} changed TypeScript file(s):`);
  files.forEach((file) => console.log(`  - ${file}`));
  execFileSync('npx', ['eslint', ...files], { stdio: 'inherit' });
  console.log('Changed files passed ESLint checks.');
} catch (error) {
  console.error('Blocking Changed-Files Lint Gate failed.');
  process.exit(1);
}
