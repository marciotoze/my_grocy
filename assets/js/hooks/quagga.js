import Quagga from 'quagga';

const beep = new Audio("/sounds/beep.mp3");

const BarcodeScannerHook = {
  mounted() {
    Quagga.init({
      inputStream: {
        name: 'Live',
        type: 'LiveStream',
        target: this.el,
        constraints: {
          facingMode: 'environment', // câmera traseira
        },
      },
      decoder: {
        readers: ['ean_reader'], // EAN-13
      },
    }, (err) => {
      if (err) {
        console.error('Quagga init error:', err);
        return;
      }
      Quagga.start();
    });

    let scanLock = false;
    let lastCodes = [];

    Quagga.onDetected((data) => {
      if (scanLock) return;

      const code = data.codeResult.code;

      // // Verifica se é EAN-13 válido (13 dígitos numéricos)
      // const isEAN13 = /^\d{13}$/.test(code);

      // // Verifica se começa com 789 (Brasil)
      // const isFromBrazil = code.startsWith("789");

      // if (isEAN13 && isFromBrazil) {
      lastCodes.push(code);
      if (lastCodes.length > 5) lastCodes.shift();

      const freq = lastCodes.filter(c => c === code).length;

      if (freq >= 3) {
        scanLock = true;
        beep.play().catch(err => console.warn("Erro ao tocar som:", err));

        this.pushEvent("barcode_scanned", {
          barcode: code,
          action: document.querySelector("input[name='action']:checked")?.value,
          quantity: document.querySelector("input[name='quantity']")?.value
        });

        setTimeout(() => {
          scanLock = false;
          lastCodes = [];
        }, 1500); // 1.5s de cooldown pra evitar leitura repetida
      }
      // }
    });
  },
  destroyed() {
    Quagga.stop();
    Quagga.offDetected();
  },
};

export default BarcodeScannerHook;
