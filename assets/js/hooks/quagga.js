import Quagga from 'quagga';

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

    Quagga.onDetected((data) => {
      const code = data.codeResult.code;
      this.pushEvent("barcode_detected", { code });
    });
  },

  destroyed() {
    Quagga.stop();
    Quagga.offDetected();
  },
};

export default BarcodeScannerHook;
