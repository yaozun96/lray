/**
 * ImgBB 图片上传服务
 * API 文档: https://api.imgbb.com/
 */

const IMGBB_API_KEY = '65a3d42daa7f2a8458754344fa591cfa';
const IMGBB_API_URL = 'https://api.imgbb.com/1/upload';

/**
 * 将文件转换为 Base64
 * @param {File} file - 文件对象
 * @returns {Promise<string>} Base64 字符串（不含 data:image 前缀）
 */
const fileToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      // 移除 data:image/xxx;base64, 前缀
      const base64 = reader.result.split(',')[1];
      resolve(base64);
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

/**
 * 上传图片到 ImgBB
 * @param {File} file - 图片文件
 * @param {Object} options - 可选参数
 * @param {string} options.name - 自定义文件名
 * @param {number} options.expiration - 过期时间（秒），范围 60-15552000
 * @returns {Promise<Object>} 上传结果
 */
export const uploadImage = async (file, options = {}) => {
  // 验证文件类型
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/bmp'];
  if (!allowedTypes.includes(file.type)) {
    throw new Error('不支持的图片格式，请上传 JPG、PNG、GIF、WebP 或 BMP 格式');
  }

  // 验证文件大小（最大 32MB）
  const maxSize = 32 * 1024 * 1024;
  if (file.size > maxSize) {
    throw new Error('图片大小不能超过 32MB');
  }

  try {
    const base64 = await fileToBase64(file);

    const formData = new FormData();
    formData.append('key', IMGBB_API_KEY);
    formData.append('image', base64);

    if (options.name) {
      formData.append('name', options.name);
    }

    if (options.expiration) {
      formData.append('expiration', options.expiration.toString());
    }

    const response = await fetch(IMGBB_API_URL, {
      method: 'POST',
      body: formData,
    });

    const result = await response.json();

    if (!result.success) {
      throw new Error(result.error?.message || '图片上传失败');
    }

    return {
      success: true,
      data: {
        id: result.data.id,
        url: result.data.url,
        displayUrl: result.data.display_url,
        thumbnailUrl: result.data.thumb?.url,
        deleteUrl: result.data.delete_url,
        width: result.data.width,
        height: result.data.height,
        size: result.data.size,
        filename: result.data.image?.filename,
      }
    };
  } catch (error) {
    console.error('图片上传错误:', error);
    throw error;
  }
};

/**
 * 批量上传图片
 * @param {File[]} files - 图片文件数组
 * @param {Object} options - 可选参数
 * @returns {Promise<Object[]>} 上传结果数组
 */
export const uploadImages = async (files, options = {}) => {
  const results = [];
  for (const file of files) {
    try {
      const result = await uploadImage(file, options);
      results.push(result);
    } catch (error) {
      results.push({
        success: false,
        error: error.message,
        filename: file.name,
      });
    }
  }
  return results;
};
