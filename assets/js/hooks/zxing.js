import { BrowserMultiFormatOneDReader } from '@zxing/browser';
import { BarcodeFormat, DecodeHintType } from '@zxing/library';

const ZXingHook = {
  mounted() {
    const videoElem = this.el.querySelector('video');
    const scanArea = this.el.querySelector('.scan-area');
    this.lastCode = null;

    const hints = new Map();
    hints.set(DecodeHintType.POSSIBLE_FORMATS, [
      BarcodeFormat.EAN_13,
      // BarcodeFormat.EAN_8,
      // BarcodeFormat.UPC_A,
      // BarcodeFormat.UPC_E
    ]);

    const constraints = {
      video: {
        facingMode: { exact: "environment" },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      }
    };

    this.codeReader = new BrowserMultiFormatOneDReader(hints, constraints);

    this.codeReader.decodeFromVideoDevice(
      undefined,
      videoElem,
      (result, error, controls) => {
        if (result) {
          const points = result.getResultPoints?.() || [];

          if (points.length > 0) {
            let xs = points.map(p => p.getX());
            let ys = points.map(p => p.getY());

            const minX = Math.min(...xs);
            const maxX = Math.max(...xs);
            const minY = Math.min(...ys);
            const maxY = Math.max(...ys);

            const videoRect = videoElem.getBoundingClientRect();
            const videoWidth = videoElem.videoWidth;
            const videoHeight = videoElem.videoHeight;
            const scaleX = videoRect.width / videoWidth;
            const scaleY = videoRect.height / videoHeight;

            const boxLeft = minX * scaleX + videoRect.left;
            const boxRight = maxX * scaleX + videoRect.left;
            const boxTop = minY * scaleY + videoRect.top;
            const boxBottom = maxY * scaleY + videoRect.top;

            const scanRect = scanArea.getBoundingClientRect();
            const margin = 20;

            const inside =
              boxLeft > (scanRect.left - margin) &&
              boxRight < (scanRect.right + margin) &&
              boxTop > (scanRect.top - margin) &&
              boxBottom < (scanRect.bottom + margin);

            if (!inside) return;
          }

          const code = result.getText();
          const now = Date.now();
          if ((isValidEAN13(code)) && (!this.lastScanAt || now - this.lastScanAt > 1500)) {
            this.lastScanAt = now;
            this.pushEvent("barcode_scanned", {
              barcode: code,
              action: document.querySelector("input[name='action']:checked")?.value,
              quantity: document.querySelector("input[name='quantity']")?.value
            });
          }
        }
      }
    );
  },

  destroyed() {
    this.codeReader?.reset();
  }
};

function isValidEAN13(code) {
  if (!/^\d{13}$/.test(code)) return false;

  const digits = code.split('').map(Number);
  const checksum =
    10 - ((digits
      .slice(0, 12)
      .reduce((acc, d, i) => acc + d * (i % 2 === 0 ? 1 : 3), 0)) % 10);
  return checksum === digits[12];
}

export default ZXingHook;