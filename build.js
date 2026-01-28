const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Check for silent flag
const args = process.argv.slice(2);
const silent = args.includes('--silent') || args.includes('-s');

function log(...messages) {
    if (!silent) {
        console.log(...messages);
    }
}

const scriptDir = __dirname;
const packagePath = path.join(scriptDir, 'package.json');
const sourcePath = path.join(scriptDir, 'PrimalLedger');
const releasesDir = path.join(scriptDir, 'releases');

// Read version from package.json
if (!fs.existsSync(packagePath)) {
    console.error('package.json not found');
    process.exit(1);
}

const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const version = packageJson.version;

if (!version) {
    console.error('No version found in package.json');
    process.exit(1);
}

// Verify source exists
if (!fs.existsSync(sourcePath)) {
    console.error('PrimalLedger folder not found');
    process.exit(1);
}

// Create releases directory if it doesn't exist
if (!fs.existsSync(releasesDir)) {
    fs.mkdirSync(releasesDir, { recursive: true });
}

const zipName = `PrimalLedger-v${version}.zip`;
const zipPath = path.join(releasesDir, zipName);

// Remove existing zip if it exists
if (fs.existsSync(zipPath)) {
    fs.unlinkSync(zipPath);
    log('Removed existing', zipName);
}

// Create zip using PowerShell (Windows) or zip command (Unix)
log('Creating', zipName);

if (process.platform === 'win32') {
    const psCommand = `Compress-Archive -Path "${sourcePath}" -DestinationPath "${zipPath}"`;
    execSync(`powershell -Command "${psCommand}"`, { stdio: 'inherit' });
} else {
    execSync(`zip -r "${zipPath}" PrimalLedger`, { cwd: scriptDir, stdio: 'inherit' });
}

log('Build complete:', zipPath);
