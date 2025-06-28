import { BrowserMultiFormatReader } from '@zxing/browser';
import { BarcodeFormat, DecodeHintType } from '@zxing/library';

const ZXingHook = {
  mounted() {
    const videoElem = this.el.querySelector('video');
    const scanArea = this.el.querySelector('.scan-area');
    this.lastCode = null;

    const hints = new Map();
    hints.set(DecodeHintType.POSSIBLE_FORMATS, [
      BarcodeFormat.EAN_13,
      BarcodeFormat.EAN_8,
      BarcodeFormat.UPC_A,
      BarcodeFormat.UPC_E
    ]);
    hints.set(DecodeHintType.TRY_HARDER, true);

    const constraints = {
      video: {
        facingMode: { exact: "environment" },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      }
    };

    this.codeReader = new BrowserMultiFormatReader(hints, constraints);

    this.codeReader.decodeFromVideoDevice(
      undefined,
      videoElem,
      (result, error, controls) => {
        if (error) {
          console.warn("ZXing error", error);
        }

        if (result) {
          const format = result.getBarcodeFormat();
          const code = result.getText();
          const now = Date.now();

          if (!isCodeInsideScanArea(result, videoElem, scanArea)) return;

          if (isValidBarcode(code, format) && (!this.lastScanAt || now - this.lastScanAt > 1500)) {
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

// Valida se o código está dentro da área de escaneamento
function isCodeInsideScanArea(result, videoElem, scanArea) {
  const points = result.getResultPoints?.() || [];
  if (points.length === 0) return true; // assume OK se sem pontos

  const xs = points.map(p => p.getX());
  const ys = points.map(p => p.getY());

  const [minX, maxX] = [Math.min(...xs), Math.max(...xs)];
  const [minY, maxY] = [Math.min(...ys), Math.max(...ys)];

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

  return (
    boxLeft > (scanRect.left - margin) &&
    boxRight < (scanRect.right + margin) &&
    boxTop > (scanRect.top - margin) &&
    boxBottom < (scanRect.bottom + margin)
  );
}

// Validação geral
function isValidBarcode(code, format) {
  switch (format) {
    case BarcodeFormat.EAN_13:
      return isValidEAN13(code);
    case BarcodeFormat.EAN_8:
      return isValidEAN8(code);
    case BarcodeFormat.UPC_A:
      return isValidUPCA(code);
    case BarcodeFormat.UPC_E:
      return isValidUPCE(code);
    default:
      return false;
  }
}

// EAN-13
function isValidEAN13(code) {
  if (!/^\d{13}$/.test(code)) return false;
  const digits = code.split('').map(Number);
  const sum = digits
    .slice(0, 12)
    .reduce((acc, d, i) => acc + d * (i % 2 === 0 ? 1 : 3), 0);
  const checksum = (10 - (sum % 10)) % 10;
  return checksum === digits[12];
}

// EAN-8
function isValidEAN8(code) {
  if (!/^\d{8}$/.test(code)) return false;
  const digits = code.split('').map(Number);
  const sum = digits
    .slice(0, 7)
    .reduce((acc, d, i) => acc + d * (i % 2 === 0 ? 3 : 1), 0);
  const checksum = (10 - (sum % 10)) % 10;
  return checksum === digits[7];
}

// UPC-A
function isValidUPCA(code) {
  if (!/^\d{12}$/.test(code)) return false;
  const digits = code.split('').map(Number);
  const sum = digits
    .slice(0, 11)
    .reduce((acc, d, i) => acc + d * (i % 2 === 0 ? 3 : 1), 0);
  const checksum = (10 - (sum % 10)) % 10;
  return checksum === digits[11];
}

// UPC-E com expansão
function isValidUPCE(code) {
  if (!/^\d{8}$/.test(code)) return false;

  const digits = code.split('').map(Number);
  const numberSystem = digits[0];
  const checkDigit = digits[7];
  const upceBody = digits.slice(1, 7);

  const upcaDigits = expandUPCEtoUPCA(numberSystem, upceBody);
  if (!upcaDigits) return false;

  const sum = upcaDigits
    .slice(0, 11)
    .reduce((acc, d, i) => acc + d * (i % 2 === 0 ? 3 : 1), 0);
  const expectedCheckDigit = (10 - (sum % 10)) % 10;

  return expectedCheckDigit === checkDigit;
}

function expandUPCEtoUPCA(ns, body) {
  const [d1, d2, d3, d4, d5, d6] = body;
  let upca = [];

  switch (d6) {
    case 0:
    case 1:
    case 2:
      // NS + D1 D2 D6 00000 D3 D4 D5
      upca = [ns, d1, d2, d6, 0, 0, 0, 0, 0, d3, d4, d5];
      break;
    case 3:
      // NS + D1 D2 D3 00000 0 D4 D5
      upca = [ns, d1, d2, d3, 0, 0, 0, 0, 0, 0, d4, d5];
      break;
    case 4:
      // NS + D1 D2 D3 D4 00000 0 0 D5
      upca = [ns, d1, d2, d3, d4, 0, 0, 0, 0, 0, 0, d5];
      break;
    default:
      // d6 == 5,6,7,8,9 → NS + D1 D2 D3 D4 D5 0000 D6
      upca = [ns, d1, d2, d3, d4, d5, 0, 0, 0, 0, 0, d6];
      break;
  }

  return upca;
}

export default ZXingHook;