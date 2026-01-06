import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const AUTH_FILE = path.resolve(__dirname, '../src/utils/auth.js');
const PATTERN = [3, 1, 4, 1, 5, 9, 2, 6];
const SECRET_PARTS = ['THJheTo=', 'RG9tYWlu', 'R3VhcmQ=', 'QDIwMjQ='];

function exitWithUsage(message) {
  console.error(`\n❌ ${message}\n`);
  console.info('用法:');
  console.info('  npm run update:api -- <API 域名 URL>');
  console.info('示例:');
  console.info('  npm run update:api -- https://api.example.com');
  process.exit(1);
}

function ensureTrailingSlash(url) {
  return url.endsWith('/') ? url : `${url}/`;
}

function doubleBase64Encode(value) {
  const once = Buffer.from(value, 'utf8').toString('base64');
  return Buffer.from(once, 'utf8').toString('base64');
}

function buildDomainSeeds(encoded) {
  const chars = [...encoded];
  return chars.map((char, index) => char.charCodeAt(0) + PATTERN[index % PATTERN.length]);
}

function normalizeUrl(url = '') {
  return url.replace(/\/+$/, '');
}

function decodeSecretParts() {
  return SECRET_PARTS.map((part) => Buffer.from(part, 'base64').toString('utf8')).join('');
}

function fingerprintDomain(origin) {
  const normalized = normalizeUrl(origin);
  if (!normalized) return '';

  const secret = decodeSecretParts();
  const payload = `${normalized}|${secret}|${normalized.length * 13}`;

  let h1 = 0x811c9dc5;
  let h2 = 0x01000193;

  for (let i = 0; i < payload.length; i++) {
    const code = payload.charCodeAt(i);
    h1 = Math.imul(h1 ^ code, 0x01000193);
    h1 >>>= 0;
    h2 ^= Math.imul(code + h2, 0x5bd1e995);
    h2 >>>= 0;
  }

  const toHex = (val) => (val >>> 0).toString(16).padStart(8, '0');
  return `${toHex(h1)}${toHex(h2)}`.toLowerCase();
}

function chunkString(str, size) {
  const chunks = [];
  for (let i = 0; i < str.length; i += size) {
    chunks.push(str.slice(i, i + size));
  }
  return chunks;
}

function formatNumberArray(values, numbersPerLine = 8) {
  const lines = [];
  for (let i = 0; i < values.length; i += numbersPerLine) {
    const slice = values.slice(i, i + numbersPerLine).join(', ');
    lines.push(`  ${slice}`);
  }
  return lines.join(',\n');
}

function formatStringArray(values, perLine = 6) {
  const lines = [];
  for (let i = 0; i < values.length; i += perLine) {
    const slice = values.slice(i, i + perLine).map((item) => `'${item}'`).join(', ');
    lines.push(`  ${slice}`);
  }
  return lines.join(',\n');
}

function replaceBlock(content, regex, replacement) {
  if (!regex.test(content)) {
    throw new Error('无法在 auth.js 中找到待替换的代码块');
  }
  return content.replace(regex, replacement);
}

function main() {
  const target = process.argv[2];

  if (!target) {
    exitWithUsage('请提供目标 API 域名');
  }

  let parsed;
  try {
    parsed = new URL(target);
  } catch (error) {
    exitWithUsage('无法解析提供的域名，请确保包含协议，如 https://api.example.com');
  }

  if (!['http:', 'https:'].includes(parsed.protocol)) {
    exitWithUsage('仅支持 http 或 https 协议');
  }

  const origin = parsed.origin;
  const authorizedOrigin = ensureTrailingSlash(origin);
  const doubleEncoded = doubleBase64Encode(authorizedOrigin);
  const domainSeeds = buildDomainSeeds(doubleEncoded);

  const fingerprint = fingerprintDomain(authorizedOrigin);
  if (!fingerprint) {
    exitWithUsage('生成指纹失败');
  }
  const fingerprintChunks = chunkString(fingerprint, 3).map((chunk) => Buffer.from(chunk, 'utf8').toString('base64'));

  let authSource = fs.readFileSync(AUTH_FILE, 'utf8');

  const seedsRegex = /const _0xDomainSeeds = Object\.freeze\(\[([\s\S]*?)\]\);/;
  const fingerprintRegex = /const _0xFingerprintSegments = Object\.freeze\(\[([\s\S]*?)\]\);/;

  const seedsBlock = `const _0xDomainSeeds = Object.freeze([\n${formatNumberArray(domainSeeds)}\n]);`;
  const fingerprintBlock = `const _0xFingerprintSegments = Object.freeze([\n${formatStringArray(fingerprintChunks)}\n]);`;

  authSource = replaceBlock(authSource, seedsRegex, seedsBlock);
  authSource = replaceBlock(authSource, fingerprintRegex, fingerprintBlock);

  fs.writeFileSync(AUTH_FILE, authSource, 'utf8');

  console.log('==========================================');
  console.log('✨ API 域名更新完成');
  console.log('==========================================');
  console.log(`🔒 授权域名: ${authorizedOrigin}`);
  console.log(`🧬 指纹值: ${fingerprint}`);
  console.log(`📦 更新文件: ${path.relative(process.cwd(), AUTH_FILE)}`);
  console.log('==========================================');
}

main();
