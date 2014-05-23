
Ensembl.Panel.RunHealthchecks = Ensembl.Panel.extend({
  init: function() {
    this.base();
    panel = this;

    $('.run-hc-button', panel.el).click(function(){
      
      if ($(this).hasClass('disabled')) {
        alert('Healthchecks are currently running.\nYou can refresh this page to check if they are done.');
        return false;
      }     

      if ($(this).hasClass('run-hc-button-busy')) {
        return false;
      }     

      var url = $(this).attr('data-url');
      
      if (url) {
        $('.run-hc-button', panel.el).addClass('run-hc-button-busy');
        $.ajax({
          type: "GET",
          url: url,
          dataType: 'json',
          success: function(data) { 
            if (data.status === 'success') {
              window.location.reload();  
            } else {
              var msg = data.status;
              if (data.error) msg += ':\n' + data.error.join('\n')
              alert(msg);
            }
          },
          error: function(xhr, msg) { 
            alert('There was a problem contacting the healthchecks webservice\nError: ' + msg) 
            $('.run-hc-button', this.el).removeClass('run-hc-button-busy');
          }
        });
      }
    });
  }
});