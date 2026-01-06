/**
 * 授权密钥生成工具
 * 用于生成新的授权密钥
 */

/**
 * 生成授权密钥
 * @returns {object} 包含密钥和混淆代码的对象
 */
function generateAuthKey() {
    const timestamp = Date.now();
    const key = `v2board_auth_${timestamp}`;
    const encoded = Buffer.from(key).toString('base64');

    // 生成混淆的代码格式
    const chars = encoded.split('');
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

    const obfuscatedCode = `const _0x3c8f = [\n${chunks.join(',\n')}\n].join('');`;

    return {
        key,
        encoded,
        obfuscatedCode
    };
}

/**
 * 生成加密的API域名
 * @param {string} domain - API域名（如: https://api.cwtgo.com/）
 * @returns {string} 双重Base64编码的域名
 */
function encryptDomain(domain) {
    // 第一次Base64编码
    let encoded = Buffer.from(domain).toString('base64');
    // 第二次Base64编码
    encoded = Buffer.from(encoded).toString('base64');
    return encoded;
}

// 主程序
console.log('======================================');
console.log('V2Board主题授权密钥生成工具');
console.log('======================================\n');

// 生成授权密钥
const authKeyData = generateAuthKey();
console.log('【授权密钥信息】');
console.log('原始密钥:', authKeyData.key);
console.log('Base64编码:', authKeyData.encoded);
console.log();

console.log('【混淆后的代码】');
console.log('将以下代码复制到 src/utils/auth.js 中替换 _0x3c8f 变量:\n');
console.log(authKeyData.obfuscatedCode);
console.log();

// 生成加密的API域名
const apiDomain = 'https://api.cwtgo.com/';
const encryptedDomain = encryptDomain(apiDomain);
console.log('【加密的API域名】');
console.log('域名:', apiDomain);
console.log('加密后:', encryptedDomain);
console.log();

console.log('======================================');
console.log('使用说明:');
console.log('1. 将上面的"混淆后的代码"复制到 src/utils/auth.js，替换 _0x3c8f 变量定义');
console.log('2. 如需更换API域名，将"加密后"的字符串更新到 src/utils/auth.js 的 _0x4a2b 变量');
console.log('3. 重新构建项目: npm run build');
console.log('\n注意: 密钥已硬编码到源码中，不再存储在 public/config.js');
console.log('======================================');
