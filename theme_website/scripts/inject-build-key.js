/**
 * 构建时密钥注入工具
 * 每次构建自动生成新的随机密钥（可选过期时间）
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * 生成随机密钥
 * @param {number} length - 密钥长度
 * @returns {string} Base64编码的随机密钥
 */
function generateRandomKey(length = 32) {
    const randomBytes = crypto.randomBytes(length);
    return randomBytes.toString('base64');
}

/**
 * 生成过期时间戳
 * @param {number} days - 过期天数
 * @returns {number} 过期时间戳
 */
function generateExpiryTime(days = 90) {
    return Date.now() + (days * 24 * 60 * 60 * 1000);
}

/**
 * 将字符串转换为混淆的字符编码数组
 * @param {string} str - 要混淆的字符串
 * @param {string} varName - 变量名
 * @returns {string} 混淆后的代码
 */
function obfuscateString(str, varName) {
    const chars = str.split('');
    const chunks = [];
    let currentChunk = '';

    for (let i = 0; i < chars.length; i++) {
        currentChunk += chars[i];
        if ((i + 1) % 8 === 0 || i === chars.length - 1) {
            const charCodes = Array.from(currentChunk).map(c => c.charCodeAt(0)).join(', ');
            chunks.push(`  String.fromCharCode(${charCodes})`);
            currentChunk = '';
        }
    }

    return `const ${varName} = [\n${chunks.join(',\n')}\n].join('');`;
}

/**
 * 生成构建信息
 * @param {number|null} expiryDays - 过期天数
 * @returns {object} 构建信息
 */
function generateBuildInfo(expiryDays = null) {
    const buildKey = generateRandomKey(32);
    const buildTime = Date.now();
    const shouldExpire = typeof expiryDays === 'number' && expiryDays > 0;
    const expiryTime = shouldExpire ? generateExpiryTime(expiryDays) : null;
    const buildId = crypto.randomBytes(8).toString('hex');

    // 创建签名：使用密钥、构建时间和过期时间生成签名
    const signatureData = shouldExpire
        ? `${buildKey}_${buildTime}_${expiryTime}`
        : `${buildKey}_${buildTime}`;
    const signature = crypto
        .createHash('sha256')
        .update(signatureData)
        .digest('base64');

    return {
        buildKey,
        buildTime,
        expiryTime,
        buildId,
        signature,
        expiryDays: shouldExpire ? expiryDays : null
    };
}

/**
 * 注入到auth.js文件
 * @param {object} buildInfo - 构建信息
 */
function injectToAuthFile(buildInfo) {
    const authFilePath = path.resolve(__dirname, '../src/utils/auth.js');
    let authContent = fs.readFileSync(authFilePath, 'utf-8');

    // 生成混淆后的构建数据
    const obfuscatedKey = obfuscateString(buildInfo.buildKey, '_0xBuildKey');
    const obfuscatedSig = obfuscateString(buildInfo.signature, '_0xBuildSig');

    // 查找要替换的标记
    const buildDataMarker = '// BUILD_DATA_INJECTION_POINT';

    const expiryLine = buildInfo.expiryTime
        ? `const _0xExpiryTime = ${buildInfo.expiryTime};`
        : 'const _0xExpiryTime = null;';

    if (!authContent.includes(buildDataMarker)) {
        // 如果没有标记，在文件开头添加
        const injectionCode = `
// BUILD_DATA_INJECTION_POINT
// 构建时动态生成的密钥（可选过期时间）
${obfuscatedKey}
${obfuscatedSig}
const _0xBuildTime = ${buildInfo.buildTime};
${expiryLine}
const _0xBuildId = '${buildInfo.buildId}';
// END_BUILD_DATA_INJECTION

`;
        authContent = injectionCode + authContent;
    } else {
        // 替换已有的构建数据
        const regex = /\/\/ BUILD_DATA_INJECTION_POINT[\s\S]*?\/\/ END_BUILD_DATA_INJECTION/;
        const injectionCode = `// BUILD_DATA_INJECTION_POINT
// 构建时动态生成的密钥（可选过期时间）
${obfuscatedKey}
${obfuscatedSig}
const _0xBuildTime = ${buildInfo.buildTime};
${expiryLine}
const _0xBuildId = '${buildInfo.buildId}';
// END_BUILD_DATA_INJECTION`;

        authContent = authContent.replace(regex, injectionCode);
    }

    fs.writeFileSync(authFilePath, authContent, 'utf-8');
}

/**
 * 保存构建信息到日志文件
 * @param {object} buildInfo - 构建信息
 */
function saveBuildLog(buildInfo) {
    const logDir = path.resolve(__dirname, '../.build-logs');
    if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
    }

    const logFile = path.join(logDir, `build-${buildInfo.buildId}.json`);
    const logData = {
        buildId: buildInfo.buildId,
        buildTime: buildInfo.buildTime,
        buildTimeReadable: new Date(buildInfo.buildTime).toISOString(),
        expiryTime: buildInfo.expiryTime,
        expiryTimeReadable: buildInfo.expiryTime
            ? new Date(buildInfo.expiryTime).toISOString()
            : null,
        expiryDays: buildInfo.expiryDays,
        expiryEnabled: Boolean(buildInfo.expiryTime),
        buildKey: buildInfo.buildKey.substring(0, 10) + '...' // 只记录部分密钥
    };

    fs.writeFileSync(logFile, JSON.stringify(logData, null, 2), 'utf-8');

    // 同时更新最新构建信息
    const latestLogFile = path.join(logDir, 'latest.json');
    fs.writeFileSync(latestLogFile, JSON.stringify(logData, null, 2), 'utf-8');
}

// 主程序
console.log('==========================================');
console.log('🔐 构建时密钥注入工具');
console.log('==========================================\n');

function parseExpiryArg(rawArg) {
    if (!rawArg) {
        return null;
    }

    const lowered = rawArg.toLowerCase();
    if (['none', 'off', 'disable', 'disabled', 'false', '0'].includes(lowered)) {
        return null;
    }

    const parsed = parseInt(rawArg, 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

// 从命令行参数或环境变量获取过期天数，默认永不过期
const rawCliArg = process.argv[2];
const rawEnvArg = process.env.BUILD_EXPIRY_DAYS || process.env.npm_config_build_expiry_days;
const rawExpiryArg = rawCliArg ?? rawEnvArg ?? null;
const expiryDays = parseExpiryArg(rawExpiryArg);
const expiryEnabled = typeof expiryDays === 'number';

if (expiryEnabled) {
    console.log(`⏰ 设置过期时间: ${expiryDays} 天后\n`);
} else {
    console.log('⏰ 已禁用过期时间：构建密钥永不过期\n');
}

// 生成构建信息
const buildInfo = generateBuildInfo(expiryDays);

console.log('📦 构建信息:');
console.log(`  构建ID: ${buildInfo.buildId}`);
console.log(`  构建时间: ${new Date(buildInfo.buildTime).toLocaleString('zh-CN')}`);
if (buildInfo.expiryTime) {
    console.log(`  过期时间: ${new Date(buildInfo.expiryTime).toLocaleString('zh-CN')}`);
    console.log(`  剩余天数: ${buildInfo.expiryDays} 天`);
} else {
    console.log('  过期时间: 永不过期');
}
console.log(`  密钥长度: ${buildInfo.buildKey.length} 字符`);
console.log(`  签名: ${buildInfo.signature.substring(0, 20)}...\n`);

// 注入到auth.js
try {
    injectToAuthFile(buildInfo);
    console.log('✅ 已成功注入动态密钥到 src/utils/auth.js\n');
} catch (error) {
    console.error('❌ 注入失败:', error.message);
    process.exit(1);
}

// 保存构建日志
try {
    saveBuildLog(buildInfo);
    console.log('✅ 已保存构建日志到 .build-logs/\n');
} catch (error) {
    console.warn('⚠️  保存构建日志失败:', error.message);
}

console.log('==========================================');
console.log('✨ 构建密钥注入完成！');
console.log('==========================================\n');

export { generateBuildInfo, injectToAuthFile };
