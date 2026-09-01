# QR 模擬器 Web Component

將 [`assets/qr-code-emulator/swaploop-qr-emulator.js`](../qr-code-emulator/swaploop-qr-emulator.js) 複製到 SPA 中（例如 `public/swaploop-qr-emulator.js`），並載入一次。這是一個 IIFE bundle：它會註冊 `<swaploop-qr-emulator>`，不需要以 bundler import `qrcode`。

```html
<script src="/swaploop-qr-emulator.js"></script>
```

將 `service-url` 設為 Station Service 的基礎 URL（不含結尾斜線）：

```text
https://cXX-YYYY-station-service.sitc.skillsit.eu
```

本機開發：`http://localhost:4020`。

變更 `scan-request-id` 會觸發一次掃描。元件會發出 `qr-scan` 事件；payload 為 `event.detail.payload`（站點深層連結或單純的 `station-…` id）。

若要選擇**作用中海報**，請開啟 Station Service 測試器：

```text
https://cXX-YYYY-station-service.sitc.skillsit.eu/qr-code-emulator
```

本機：`http://localhost:4020/qr-code-emulator`。在此設定海報，然後在 SPA 中觸發掃描。

## React

```jsx
import { useEffect, useState } from "react";

const [requestId, setRequestId] = useState(0);

useEffect(() => {
  const receive = (event) => console.log(event.detail.payload);
  window.addEventListener("qr-scan", receive);
  return () => window.removeEventListener("qr-scan", receive);
}, []);

<swaploop-qr-emulator
  service-url="https://cXX-YYYY-station-service.sitc.skillsit.eu"
  scan-request-id={requestId}
/>
<button onClick={() => setRequestId((id) => id + 1)}>Scan</button>
```

以 `index.html` 中的 `<script>` 載入 IIFE（或同等的靜態引入方式）。除非你的 bundler 已針對該 IIFE 檔案做特別設定，否則請勿將 bundle 以 ES module 的方式 `import`。

## Vue

為以 `swaploop-` 開頭的標籤設定 Vue 的 `isCustomElement` 選項。

```vue
<script>
export default {
  data: () => ({ requestId: 0 }),
  methods: {
    handleScan(event) {
      console.log(event.detail.payload);
    }
  }
};
</script>

<template>
  <swaploop-qr-emulator
    service-url="https://cXX-YYYY-station-service.sitc.skillsit.eu"
    :scan-request-id="requestId"
    @qr-scan="handleScan"
  />
  <button @click="requestId++">Scan</button>
</template>
```

## Angular

將 `CUSTOM_ELEMENTS_SCHEMA` 加入元件或模組的 schemas。

```html
<swaploop-qr-emulator
  service-url="https://cXX-YYYY-station-service.sitc.skillsit.eu"
  [attr.scan-request-id]="requestId"
  (qr-scan)="handleScan($event)">
</swaploop-qr-emulator>

<button (click)="requestId = requestId + 1">Scan</button>
```

```ts
requestId = 0;

handleScan(event: Event) {
  console.log((event as CustomEvent).detail.payload);
}
```
