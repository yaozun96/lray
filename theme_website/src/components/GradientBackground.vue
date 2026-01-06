<template>
  <div class="gradient-bg">
    <div class="gradient-blob blob-1"></div>
    <div class="gradient-blob blob-2"></div>
    <div class="gradient-blob blob-3"></div>
    <div class="gradient-blob blob-4"></div>
  </div>
</template>

<style scoped>
.gradient-bg {
  position: fixed;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
  z-index: -1;
  background-color: #fafafa;
}

:deep(.dark) .gradient-bg,
.dark .gradient-bg {
  background-color: #09090b;
}

.gradient-blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  will-change: transform;
}

.blob-1 {
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, rgba(59, 130, 246, 0.12) 0%, transparent 70%);
  animation: moveBlob1 25s ease-in-out infinite;
}

.blob-2 {
  width: 450px;
  height: 450px;
  background: radial-gradient(circle, rgba(139, 92, 246, 0.1) 0%, transparent 70%);
  animation: moveBlob2 30s ease-in-out infinite;
}

.blob-3 {
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(6, 182, 212, 0.1) 0%, transparent 70%);
  animation: moveBlob3 28s ease-in-out infinite;
}

.blob-4 {
  width: 350px;
  height: 350px;
  background: radial-gradient(circle, rgba(244, 114, 182, 0.08) 0%, transparent 70%);
  animation: moveBlob4 32s ease-in-out infinite;
}

@keyframes moveBlob1 {
  0% { top: -10%; left: -10%; }
  25% { top: 20%; left: 70%; }
  50% { top: 60%; left: 50%; }
  75% { top: 30%; left: 10%; }
  100% { top: -10%; left: -10%; }
}

@keyframes moveBlob2 {
  0% { top: 70%; right: -10%; }
  25% { top: 10%; right: 30%; }
  50% { top: 40%; right: 70%; }
  75% { top: 80%; right: 40%; }
  100% { top: 70%; right: -10%; }
}

@keyframes moveBlob3 {
  0% { bottom: -10%; left: 30%; }
  25% { bottom: 50%; left: 60%; }
  50% { bottom: 20%; left: -5%; }
  75% { bottom: 60%; left: 40%; }
  100% { bottom: -10%; left: 30%; }
}

@keyframes moveBlob4 {
  0% { top: 50%; left: 50%; }
  25% { top: 10%; left: 20%; }
  50% { top: 70%; left: 80%; }
  75% { top: 30%; left: 60%; }
  100% { top: 50%; left: 50%; }
}

.dark .blob-1 {
  background: radial-gradient(circle, rgba(59, 130, 246, 0.18) 0%, transparent 70%);
}

.dark .blob-2 {
  background: radial-gradient(circle, rgba(139, 92, 246, 0.15) 0%, transparent 70%);
}

.dark .blob-3 {
  background: radial-gradient(circle, rgba(6, 182, 212, 0.15) 0%, transparent 70%);
}

.dark .blob-4 {
  background: radial-gradient(circle, rgba(244, 114, 182, 0.12) 0%, transparent 70%);
}
</style>
