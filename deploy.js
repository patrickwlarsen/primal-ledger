const fs = require('fs');
const path = require('path');

// Check for silent flag
const args = process.argv.slice(2);
const silent = args.includes('--silent') || args.includes('-s');

function log(...messages) {
    if (!silent) {
        console.log(...messages);
    }
}

const scriptDir = __dirname;
const configPath = path.join(scriptDir, 'config.json');

// Read config
if (!fs.existsSync(configPath)) {
    console.error('config.json not found at', configPath);
    process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const addonInstallPath = config.addonInstallPath;

if (!addonInstallPath) {
    console.error('Please update addonInstallPath in config.json with your actual WoW AddOns folder');
    process.exit(1);
}

const sourcePath = path.join(scriptDir, 'PrimalLedger');
const destPath = path.join(addonInstallPath, 'PrimalLedger');

// Verify source exists
if (!fs.existsSync(sourcePath)) {
    console.error('Source folder not found:', sourcePath);
    process.exit(1);
}

// Verify addon install path exists
if (!fs.existsSync(addonInstallPath)) {
    console.error('Addon install path not found:', addonInstallPath);
    process.exit(1);
}

// Remove existing addon folder if it exists
if (fs.existsSync(destPath)) {
    log('Removing existing addon at', destPath);
    fs.rmSync(destPath, { recursive: true, force: true });
}

// Copy addon folder recursively
function copyDir(src, dest) {
    fs.mkdirSync(dest, { recursive: true });
    const entries = fs.readdirSync(src, { withFileTypes: true });

    for (const entry of entries) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);

        if (entry.isDirectory()) {
            copyDir(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

log('Copying PrimalLedger to', destPath);
copyDir(sourcePath, destPath);

log('Deploy complete!');
