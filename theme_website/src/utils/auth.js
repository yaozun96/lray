/**
 * 授权验证模块
 * 用于防止前端主题被盗用
 */

// BUILD_DATA_INJECTION_POINT
// 构建时动态生成的密钥（可选过期时间）
const _0xBuildKey = [
  String.fromCharCode(108, 53, 72, 121, 50, 82, 116, 56),
  String.fromCharCode(97, 78, 52, 53, 47, 116, 101, 112),
  String.fromCharCode(109, 52, 98, 106, 69, 75, 70, 112),
  String.fromCharCode(89, 54, 52, 87, 110, 86, 57, 107),
  String.fromCharCode(66, 116, 113, 66, 82, 78, 89, 79),
  String.fromCharCode(74, 114, 65, 61)
].join('');
const _0xBuildSig = [
  String.fromCharCode(43, 55, 80, 49, 106, 101, 80, 68),
  String.fromCharCode(107, 47, 53, 48, 113, 90, 51, 100),
  String.fromCharCode(122, 109, 109, 97, 105, 48, 109, 89),
  String.fromCharCode(103, 113, 101, 118, 54, 99, 69, 99),
  String.fromCharCode(103, 97, 52, 53, 113, 109, 67, 110),
  String.fromCharCode(78, 104, 99, 61)
].join('');
const _0xBuildTime = 1766793505903;
const _0xExpiryTime = null;
const _0xBuildId = '44d2f9396dfd5770';
// END_BUILD_DATA_INJECTION

// 加密的授权域名（多层混淆）
const _0xDomainSeeds = Object.freeze([
  92, 86, 108, 84, 82, 80, 80, 79, 87, 85, 94, 78, 106, 93, 110, 117,
  92, 49, 104, 115, 105, 95, 109, 128, 93, 69, 70, 98, 82, 115, 106, 55,
  90, 85, 77, 54, 105, 78, 122, 57, 83, 85, 52, 62
]);
const _0xDomainPattern = Object.freeze([3, 1, 4, 1, 5, 9, 2, 6]);

// 硬编码的授权密钥（混淆存储）
const _0x3c8f = [
  String.fromCharCode(100, 106, 74, 105, 98, 50, 70, 121),
  String.fromCharCode(90, 70, 57, 104, 100, 88, 82, 111),
  String.fromCharCode(88, 122, 69, 51, 77, 122, 81, 119),
  String.fromCharCode(78, 122, 99, 119, 77, 68, 65, 119),
  String.fromCharCode(77, 68, 65, 61)
].join('');

// 域名指纹和指纹密钥
const _0xFingerprintSegments = Object.freeze([
  'NjAy', 'YzM1', 'YjZj', 'NzRi', 'YmVh', 'NQ=='
]);
const _0xFingerprintSecretParts = Object.freeze([
  'THJheTo=', 'RG9tYWlu', 'R3VhcmQ=', 'QDIwMjQ='
]);

// HTTP实例锁集合
const _lockedHttpClients = typeof WeakSet !== 'undefined'
  ? new WeakSet()
  : {
    _items: new Set(),
    add(value) {
      this._items.add(value);
    },
    has(value) {
      return this._items.has(value);
    }
  };

let _cachedAuthorizedOrigin = null;
let _cachedFingerprintSecret = null;
let _cachedExpectedFingerprint = null;

// 构建时密钥校验
const _0x5d9a = () => {
  const _k1 = String.fromCharCode(118, 50, 98, 111, 97, 114, 100);
  const _k2 = String.fromCharCode(97, 117, 116, 104);
  return `${_k1}_${_k2}`;
};

function _base64Decode(encoded) {
  if (!encoded) {
    return '';
  }

  if (typeof atob === 'function') {
    return atob(encoded);
  }

  if (typeof Buffer !== 'undefined') {
    try {
      return Buffer.from(encoded, 'base64').toString('binary');
    } catch (e) {
      return '';
    }
  }

  return '';
}

/**
 * 简单解密函数
 * @param {string} encoded - 加密字符串
 * @returns {string} 解密后的字符串
 */
function _decode(encoded) {
  try {
    // 双重Base64解密
    let decoded = _base64Decode(encoded);
    decoded = _base64Decode(decoded);
    return decoded;
  } catch (e) {
    return '';
  }
}

function _recoverDomainPayload() {
  return _0xDomainSeeds
    .map((code, index) => String.fromCharCode(code - _0xDomainPattern[index % _0xDomainPattern.length]))
    .join('');
}

function _normalizeUrl(url = '') {
  if (!url || typeof url !== 'string') {
    return '';
  }
  return url.replace(/\/+$/, '');
}

function _getFingerprintSecret() {
  if (_cachedFingerprintSecret) {
    return _cachedFingerprintSecret;
  }
  _cachedFingerprintSecret = _0xFingerprintSecretParts
    .map(part => _base64Decode(part))
    .join('');
  return _cachedFingerprintSecret;
}

function _getExpectedFingerprint() {
  if (_cachedExpectedFingerprint) {
    return _cachedExpectedFingerprint;
  }
  _cachedExpectedFingerprint = _0xFingerprintSegments
    .map(part => _base64Decode(part))
    .join('');
  return _cachedExpectedFingerprint;
}

function _fingerprintDomain(origin) {
  const normalized = _normalizeUrl(origin);
  if (!normalized) {
    return '';
  }

  const secret = _getFingerprintSecret();
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

function _resolveAllowedOrigin() {
  const payload = _recoverDomainPayload();
  return _decode(payload);
}

export function getAuthorizedApiOrigin() {
  if (!_cachedAuthorizedOrigin) {
    _cachedAuthorizedOrigin = _resolveAllowedOrigin();
  }
  return _cachedAuthorizedOrigin;
}

export function guardHttpClient(httpInstance) {
  const allowedOrigin = getAuthorizedApiOrigin();
  const normalized = _normalizeUrl(allowedOrigin);
  const lockedBaseURL = normalized ? `${normalized}/` : allowedOrigin;

  if (!httpInstance || typeof httpInstance !== 'object' || !httpInstance.defaults) {
    return lockedBaseURL;
  }

  if (!httpInstance.defaults.baseURL) {
    httpInstance.defaults.baseURL = lockedBaseURL;
  }

  if (_lockedHttpClients.has(httpInstance) || import.meta.env?.DEV) {
    return lockedBaseURL;
  }

  _lockedHttpClients.add(httpInstance);

  try {
    Object.defineProperty(httpInstance.defaults, 'baseURL', {
      configurable: false,
      enumerable: true,
      get() {
        return lockedBaseURL;
      },
      set(nextValue) {
        if (!nextValue) {
          return;
        }
        const normalizedIncoming = _normalizeUrl(nextValue);
        if (normalizedIncoming && normalizedIncoming !== normalized) {
          _onAuthFailed('检测到未授权的 API 域名修改');
        }
      }
    });
  } catch (error) {
    console.warn('[Auth] baseURL锁定失败:', error);
  }

  return lockedBaseURL;
}

/**
 * 提取URL的域名
 * @param {string} url - 完整URL
 * @returns {string} 域名
 */
function _extractDomain(url) {
  try {
    const urlObj = new URL(url);
    return urlObj.origin;
  } catch (e) {
    return '';
  }
}

/**
 * 验证API域名是否授权
 * @param {string} apiUrl - API基础URL
 * @returns {boolean} 是否授权
 */
export function verifyApiDomain(apiUrl) {
  const allowedDomain = getAuthorizedApiOrigin();
  const currentDomain = _extractDomain(apiUrl);

  // 开发环境检查
  const isDev = import.meta.env?.DEV;

  // 标准化域名：移除末尾斜杠进行比较
  const normalizedAllowed = _normalizeUrl(allowedDomain);
  const normalizedCurrent = _normalizeUrl(currentDomain);

  // 严格比较域名
  if (!normalizedCurrent || normalizedCurrent !== normalizedAllowed) {
    console.error(`[Auth] API域名验证失败`);
    console.error(`[Auth] 期望域名: ${allowedDomain}`);
    console.error(`[Auth] 当前域名: ${currentDomain}`);

    if (!isDev) {
      _onAuthFailed('域名验证失败');
      return false;
    }
    console.warn('[Auth] 开发环境：跳过域名验证');
    return true;
  }

  const fingerprint = _fingerprintDomain(normalizedCurrent);
  const expectedFingerprint = _getExpectedFingerprint();

  if (!fingerprint || fingerprint !== expectedFingerprint) {
    console.error('[Auth] API域名指纹校验失败');

    if (!isDev) {
      _onAuthFailed('API域名指纹不匹配');
      return false;
    }
    console.warn('[Auth] 开发环境：跳过指纹验证');
    return true;
  }

  return true;
}

/**
 * 验证授权密钥
 * @param {string} key - 配置中的授权密钥
 * @returns {boolean} 是否有效
 */
export function verifyAuthKey(key) {
  if (!key || typeof key !== 'string') {
    _onAuthFailed('授权密钥无效');
    return false;
  }

  // 解密并验证密钥格式
  try {
    const decoded = atob(key);
    const parts = decoded.split('_');

    if (parts.length < 3) {
      _onAuthFailed('授权密钥格式错误');
      return false;
    }

    // 验证密钥前缀
    if (parts[0] !== 'v2board' || parts[1] !== 'auth') {
      _onAuthFailed('授权密钥不匹配');
      return false;
    }

    return true;
  } catch (e) {
    _onAuthFailed('授权密钥解析失败');
    return false;
  }
}

/**
 * 验证构建是否过期
 * @returns {boolean} 是否有效
 */
function verifyBuildExpiry() {
  // 过期检查已禁用
  return true;
}

/**
 * 生成授权密钥（用于合法授权）
 * @returns {object} 包含密钥和混淆代码的对象
 */
export function generateAuthKey() {
  const timestamp = Date.now();
  const key = `v2board_auth_${timestamp}`;
  const encoded = btoa(key);

  // 生成混淆的代码格式
  const chars = encoded.split('');
  const chunks = [];
  let currentChunk = '';

  for (let i = 0; i < chars.length; i++) {
    currentChunk += chars[i];
    if ((i + 1) % 8 === 0 || i === chars.length - 1) {
      const charCodes = Array.from(currentChunk).map(c => c.charCodeAt(0)).join(', ');
      chunks.push(`String.fromCharCode(${charCodes})`);
      currentChunk = '';
    }
  }

  const obfuscatedCode = `const _0x3c8f = [\n  ${chunks.join(',\n  ')}\n].join('');`;

  return {
    key,
    encoded,
    obfuscatedCode
  };
}

/**
 * 授权失败处理
 * @param {string} reason - 失败原因
 */
function _onAuthFailed(reason) {
  // 清空控制台（仅生产环境）
  if (console.clear && import.meta.env.PROD) {
    console.clear();
  }

  // 严格模式：显示错误页面
  setTimeout(() => {
    document.body.innerHTML = `
      <div style="
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100vh;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      ">
        <div style="
          text-align: center;
          color: white;
          padding: 40px;
          background: rgba(255, 255, 255, 0.1);
          border-radius: 20px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        ">
          <div style="font-size: 72px; margin-bottom: 20px;">🔒</div>
          <h1 style="font-size: 32px; margin-bottom: 10px;">未授权使用</h1>
          <p style="font-size: 18px; opacity: 0.9; margin-bottom: 20px;">
            此主题未经授权，无法使用
          </p>
          <p style="font-size: 14px; opacity: 0.7;">
            错误代码: ${btoa(reason)}
          </p>
        </div>
      </div>
    `;
  }, 100);

  // 阻止进一步执行
  throw new Error('Authorization failed');
}

/**
 * 反调试检测（仅生产环境启用）
 */
export function initAntiDebug() {
  // 开发环境下跳过反调试
  if (import.meta.env.DEV) {
    console.log('[开发模式] 反调试功能已禁用');
    return;
  }

  // 检测DevTools
  const detectDevTools = () => {
    const widthThreshold = window.outerWidth - window.innerWidth > 160;
    const heightThreshold = window.outerHeight - window.innerHeight > 160;

    if (widthThreshold || heightThreshold) {
      // DevTools检测到，但不阻止（避免误判）
      console.clear();
    }
  };

  // 定期检测
  setInterval(detectDevTools, 1000);

  // 禁用F12和Ctrl+Shift+I
  document.addEventListener('keydown', (e) => {
    if (
      e.key === 'F12' ||
      (e.ctrlKey && e.shiftKey && e.key === 'I') ||
      (e.ctrlKey && e.shiftKey && e.key === 'C') ||
      (e.ctrlKey && e.shiftKey && e.key === 'J') ||
      (e.ctrlKey && e.key === 'U')
    ) {
      e.preventDefault();
    }
  });
}

/**
 * 初始化授权验证
 * @param {Object} config - 配置对象（保留兼容性）
 * @returns {boolean} 验证是否通过
 */
export function initAuth(config) {
  try {
    // 开发环境检查
    const isDev = import.meta.env.DEV;

    // 1. 验证构建过期时间（动态密钥机制）
    if (!verifyBuildExpiry()) {
      if (!isDev) {
        _onAuthFailed('构建已过期');
        return false;
      }
      console.warn('[Auth] 开发环境：构建过期但继续运行');
    }

    // 2. 验证硬编码的授权密钥
    const hardcodedKey = _0x3c8f;

    if (!hardcodedKey) {
      console.error('[Auth] 授权密钥未配置');
      if (!isDev) {
        _onAuthFailed('授权密钥未配置');
        return false;
      }
      console.warn('[Auth] 开发环境：跳过密钥检查');
      return true;
    }

    // 验证密钥
    if (!verifyAuthKey(hardcodedKey)) {
      if (!isDev) {
        return false;
      }
      console.warn('[Auth] 开发环境：密钥验证失败，但继续运行');
      return true;
    }

    // 3. 验证密钥格式
    try {
      const decoded = atob(hardcodedKey);
      const checkKey = _0x5d9a();
      if (!decoded.startsWith(checkKey)) {
        if (!isDev) {
          _onAuthFailed('密钥格式不正确');
          return false;
        }
      }
    } catch (e) {
      if (!isDev) {
        _onAuthFailed('密钥验证异常');
        return false;
      }
    }

    // 4. 启动反调试保护（仅生产环境）
    if (!isDev) {
      initAntiDebug();
    }

    console.log('[Auth] 授权验证通过');
    return true;
  } catch (e) {
    console.error('[Auth] 授权初始化异常:', e);
    if (!import.meta.env.DEV) {
      _onAuthFailed('授权初始化失败');
      return false;
    }
    console.warn('[Auth] 开发环境：忽略异常，继续运行');
    return true;
  }
}
