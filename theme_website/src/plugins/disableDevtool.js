const DISABLE_DEVTOOL_CDN = 'https://cdn.jsdelivr.net/npm/disable-devtool@0.3.9';
let isInitialized = false;

export function setupDisableDevtool(customOptions = {}) {
  if (typeof window === 'undefined' || isInitialized) {
    return;
  }
  isInitialized = true;

  const script = document.createElement('script');
  script.src = DISABLE_DEVTOOL_CDN;
  script.async = true;
  script.onload = () => {
    if (typeof window.DisableDevtool === 'function') {
      window.DisableDevtool({
        // 允许所有常规操作
        disableMenu: false,
        disableSelect: false,
        disableCopy: false,
        disableCut: false,
        disablePaste: false,
        clearLog: false,
        // 检测到开发者工具时跳转
        url: 'about:blank',
        ondevtoolopen: () => {
          window.location.replace('about:blank');
        },
        ...customOptions
      });
    }
  };
  document.head.appendChild(script);
}

