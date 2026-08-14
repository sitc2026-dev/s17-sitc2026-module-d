# QR emulator Web Component

Copy [`assets/qr-code-emulator/swaploop-qr-emulator.js`](../qr-code-emulator/swaploop-qr-emulator.js) into the SPA (for example `public/swaploop-qr-emulator.js`) and load it once. It is an IIFE bundle: it registers `<swaploop-qr-emulator>` and does not need a bundler import of `qrcode`.

```html
<script src="/swaploop-qr-emulator.js"></script>
```

Set `service-url` to the Station Service base URL (no trailing slash):

```text
https://cXX-YYYY-station-service.sitc.skillsit.eu
```

Local development: `http://localhost:4020`.

Changing `scan-request-id` starts one scan. The component emits `qr-scan`; the payload is `event.detail.payload` (a station deep link or a bare `station-…` id).

To choose the **active poster**, open the Station Service tester:

```text
https://cXX-YYYY-station-service.sitc.skillsit.eu/qr-code-emulator
```

Local: `http://localhost:4020/qr-code-emulator`. Set the poster there, then trigger a scan in the SPA.

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

Load the IIFE with a `<script>` in `index.html` (or the equivalent static include). Do not `import` the bundle as an ES module unless your bundler is configured for that IIFE file.

## Vue

Configure Vue's `isCustomElement` option for tags starting with `swaploop-`.

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

Add `CUSTOM_ELEMENTS_SCHEMA` to the component or module schemas.

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
