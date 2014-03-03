/*!
 * Evercam JavaScript Library v0.2.1
 * http://evercam.io/
 *
 * Copyright 2014 Evercam.io
 * Released under the MIT license
 *
 * Date: 2014-03-03
 */
(function(window, $) {

  "use strict";

  function url(base, ext) {
    if (ext === undefined) {
      ext = '';
    } else {
      ext = '/' + ext;
    }
    return window.Evercam.apiUrl + '/' + base + ext;
  }

  window.Evercam = {

    apiUrl: 'https://dashboard.evercam.io/v1',
    refresh: 0,

    setApiUrl: function(url) {
      this.apiUrl = url;
    },

    Model: {
      base: url.bind(this, 'models'),

      all: function() {
        return $.getJSON(this.url()).then(function(data) {
          return data.vendors;
        });
      },

      by_vendor: function (vid) {
        return $.getJSON(this.url(vid)).then(function(data) {
          return data.vendors[0];
        });
      },

      by_model: function (vid, mid) {
        return $.getJSON(this.url(vid + '/' + mid)).then(function(data) {
          return data.models[0];
        });
      }
    },

    Vendor: {
      url: url.bind(this, 'vendors'),

      all: function () {
        return $.getJSON(this.url()).then(function(data) {
          return data.vendors;
        });
      },

      by_mac: function (mac) {
        return $.getJSON(this.url(mac)).then(function(data) {
          return data.vendors;
        });
      }
    },

    Camera: function (name) {
      this.data = null;
      this.timestamp = 0;
      this.name = name;
    },

    User: function (login) {
      this.data = null;
      this.login = login;
    }

  };

  // USER DEFINITION
  // ====

  Evercam.User.url = url.bind(this, 'users');

  Evercam.User.create = function (params) {
    return $.post(this.url(), params).then(function(data) {
      return data.users[0];
    });
  };

  Evercam.User.cameras = function (uid) {
    return $.getJSON(this.url(uid + '/cameras')).then(function(data) {
      return data.cameras;
    });
  };

  Evercam.User.by_login = function (login) {
    var user = new Evercam.User(login);
    return $.getJSON(this.url(login)).then(function (data) {
      user.data = data.users[0];
      return user;
    });
  };

  Evercam.User.prototype.update = function (fields) {
    var self = this,
      newdata = self.data;
    if (fields !== undefined) {
      newdata = {};
      $.each(fields, function(i, val) {
        newdata[val] = self.data[val];
      });
    }
    return $.ajax({
      type: 'PATCH',
      url: Evercam.User.url(self.login),
      dataType: 'json',
      data: newdata
    });
  };

  // CAMERA DEFINITION
  // =======================

  Evercam.Camera.url = url.bind(this, 'cameras');

  Evercam.Camera.by_id = function (id) {
    var camera = new Evercam.Camera(id);
    return $.getJSON(this.url(id)).then(function (data) {
      camera.data = data.cameras[0];
      return camera;
    });
  };

  Evercam.Camera.remove = function (id) {
    return $.ajax({
      type: 'DELETE',
      url: this.url(id),
      dataType: 'json',
      data: {}
    });
  };

  Evercam.Camera.create = function (params) {
    return $.ajax({
      type: 'POST',
      url: this.url(),
      dataType: 'json',
      data: params
    });
  };

  Evercam.Camera.snapshotUrl = function (id) {
    return this.url(id + '/snapshot.jpg');
  };

  Evercam.Camera.prototype.update = function (fields) {
    var self = this,
      newdata = self.data;
    if (fields !== undefined) {
      newdata = {};
      $.each(fields, function(i, val) {
        newdata[val] = self.data[val];
      });
    }
    return $.ajax({
      type: 'PATCH',
      url: Evercam.Camera.url(self.data.id),
      dataType: 'json',
      data: newdata
    });
  };

  // EVERCAM PLUGIN DEFINITION
  // =======================

  $.fn.camera = function(opts) {

    // override defaults
    var settings = $.extend({
        refresh: Evercam.refresh
      }, opts),
      $img = $(this),
      watcher = null,
      url = Evercam.Camera.snapshotUrl(settings.name),
      updateImage = function() {
        if (settings.refresh > 0) {
          watcher = setTimeout(updateImage, settings.refresh);
        }
        $("<img />").attr('src', url)
          .load(function() {
            if (!this.complete || this.naturalWidth === undefined || this.naturalWidth === 0) {
              console.log('broken image!');
            } else {
              $img.attr('src', url);
            }
          });
      };

    // check img auto refresh
    $img.on('abort', function() {
      clearTimeout(watcher);
    });

    updateImage();

    return this;

  };

  function enableEvercam() {
    $.each($('img[evercam]'), function(i, e) {
      var $img = $(e),
        name = $img.attr('evercam'),
        refresh = Number($img.attr('refresh'));

      // ensure number
      if (isNaN(refresh)) {
        refresh = Evercam.refresh;
      }

      if (name === undefined) {
        throw "Camera name can't be empty";
      }

      $img.camera({
        name: name,
        refresh: refresh
      });
    });
  }

  $(window).load(enableEvercam);

}(window, jQuery));
