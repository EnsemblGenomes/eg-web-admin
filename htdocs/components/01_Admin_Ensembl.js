Ensembl.extend({
  initialize: function () {
    this.base();
    $('textarea._eg_tinymce').livequery(function() {
      $(this).tinymce({
        script_url: '/tiny_mce/jscripts/tiny_mce/tiny_mce.js',
        theme: "advanced",
        theme_advanced_buttons1: "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect",
        theme_advanced_buttons2: "cut,copy,paste,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,cleanup,code,image,|,removeformat,visualaid,|,sub,sup,|,charmap",
        theme_advanced_buttons3: "",
        theme_advanced_toolbar_location: "top",
        width: "800",
        height: "400",
        convert_urls: false,
        relative_urls: false
      });
    });
    $('select.dropdown_redirect', this.el).on('change', function () {
      Ensembl.redirect(this.value);
    });
    $('input.click_to_reset', this.el).on('click', function () {
      window.location.reload();
    });
    $('input.click_highlight', this.el).on('click', function () {
      this.focus();
      this.select();
    });
    $('select.dropdown_select_tag', this.el).on('change', function () {
      var fields = document.getElementsByTagName('input');
      for(var i=0;i<fields.length;i++){
        if(fields[i].name == 'tag'){
          fields[i].value = this.value;
          break;
        }
      }
    });
  }
});

