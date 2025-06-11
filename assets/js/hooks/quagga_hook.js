import Quagga from "quagga";

export const QuaggaHook = {
  mounted() {
    Quagga.init({
      inputStream: {
        name: "Live",
        type: "LiveStream",
        target: this.el,
        constraints: {
          facingMode: "environment" // câmera traseira em mobile
        }
      },
      decoder: {
        readers: ["ean_reader"]
      },
      locate: true
    }, (err) => {
      if (err) {
        console.error("Quagga init error:", err);
        return;
      }

      Quagga.start();

      Quagga.onDetected((result) => {
        const code = result.codeResult.code;
        console.log("EAN-13 detected:", code);
      });
    });
  },

  destroyed() {
    Quagga.stop();
    Quagga.offDetected(); // remove o listener para evitar vazamento
  }
};