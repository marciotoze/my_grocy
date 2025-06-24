const Toast = {
  mounted() {
    this.handleEvent('toast', (payload) => {
      const alert = this.el.querySelector(".alert");
      const type = payload.type || 'primary'; // Default to 'info' if no type is provided

      $(alert).addClass(`alert-${type}`);
      $(alert).html(payload.message);

      const toast = new bootstrap.Toast(this.el, { delay: 1000 });
      toast.show();
    })
  }
};

export default Toast;
