// ==UserScript==
// @name         Xboard 工单图片渲染
// @namespace    http://tampermonkey.net/
// @version      1.1
// @description  自动将工单中的 Markdown 图片格式渲染成真实图片
// @author       Lray
// @match        *://api.cwtgo.com/*
// @match        *://*.cwtgo.com/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // Markdown 图片正则: [图片](url) 或 ![alt](url)
    const markdownImageRegex = /\[图片\]\((https?:\/\/[^\s)]+)\)|!\[([^\]]*)\]\((https?:\/\/[^\s)]+)\)/g;

    function renderImages() {
        // 扫描整个页面的文本内容
        const bodyHtml = document.body.innerHTML;

        // 检查是否有需要替换的内容
        if (!markdownImageRegex.test(bodyHtml)) {
            return;
        }

        // 重置正则
        markdownImageRegex.lastIndex = 0;

        // 遍历所有文本节点
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );

        const nodesToReplace = [];

        while (walker.nextNode()) {
            const node = walker.currentNode;
            const text = node.textContent;

            // 跳过脚本和样式标签
            const parent = node.parentElement;
            if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE' || parent.tagName === 'TEXTAREA') {
                continue;
            }

            // 检查是否包含图片链接
            markdownImageRegex.lastIndex = 0;
            if (markdownImageRegex.test(text)) {
                nodesToReplace.push(node);
            }
        }

        // 替换节点
        nodesToReplace.forEach(node => {
            const text = node.textContent;
            markdownImageRegex.lastIndex = 0;

            const newHtml = text.replace(markdownImageRegex, (match, url1, alt, url2) => {
                const url = url1 || url2;
                return `<img src="${url}" alt="${alt || '图片'}" style="max-width: 100%; max-height: 400px; border-radius: 8px; margin: 8px 0; cursor: pointer; display: block;" onclick="window.open('${url}', '_blank')" />`;
            });

            if (newHtml !== text) {
                const span = document.createElement('span');
                span.innerHTML = newHtml;
                node.parentNode.replaceChild(span, node);
            }
        });

        if (nodesToReplace.length > 0) {
            console.log(`[Xboard 工单图片渲染] 已渲染 ${nodesToReplace.length} 个图片`);
        }
    }

    // 延迟执行，等待页面加载
    setTimeout(renderImages, 1500);
    setTimeout(renderImages, 3000);

    // 监听 DOM 变化（SPA 应用）
    let debounceTimer;
    const observer = new MutationObserver(() => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(renderImages, 800);
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true
    });

    console.log('[Xboard 工单图片渲染] 脚本已加载 v1.1');
})();
