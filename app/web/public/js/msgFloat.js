(function($) {

  $(document).ready(function() {

    var msgFloat = function(element, type) {

      var $this = $(element);
      var message = $this.attr("data-" + type);

      $this.wrap("<div class='msg-float'>");
      $this.before("<span class='msg-holder msg-" + type + "'>" + message);

      $this.on('focus', function() {
        $this.siblings('.msg-holder').addClass('active');
      });

      $this.on('keyup blur', function() {
        $this.siblings('.msg-holder').removeClass('active');
      });

    }

    $('.form-control[data-error]:not([type=submit])').each(function(i,e) {
      msgFloat(e, 'error');
    });

    $('.form-control[data-notice]:not([type=submit])').each(function(i,e) {
      msgFloat(e, 'notice');
    });

  });

})(window.jQuery);

