/*!
 * Evercam JavaScript Library v0.1.4
 * http://evercam.io/
 *
 * Copyright 2014 Evercam.io
 * Released under the MIT license
 *
 * Date: 2014-01-22
 */
(function(window, $) {

  "use strict";

  window.Evercam = {

    apiUrl: 'https://api.evercam.io/v1',
    proxyUrl: 'http://cors.evr.cm/',
    refresh: 0,

    setApiUrl: function(url) {
      this.apiUrl = url;
    },

    setBasicAuth: function(username, password) {
      $.ajaxSetup({
        headers: {
          'Authorization': 'Basic ' + base64Encode(username + ":" + password)
        }
      });
    },

    Model: {
      url: function(ext){
        if (typeof(ext) === 'undefined') ext = '';
        else ext = '/' + ext;
        return window.Evercam.apiUrl + '/models' + ext;
      },

      all: function(callback) {
        $.getJSON(this.url(), function(data) {
          callback(data.vendors);
        });
      },

      by_vendor: function (vid, callback) {
        $.getJSON(this.url(vid), function(data) {
          callback(data.vendors[0]);
        });
      },

      by_model: function (vid, mid, callback) {
        $.getJSON(this.url(vid + '/' + mid), function(data) {
          callback(data.models[0]);
        });
      }
    },

    User: {
      url: function(ext){
        if (typeof(ext) === 'undefined') ext = '';
        else ext = '/' + ext;
        return window.Evercam.apiUrl + '/users' + ext;
      },

      create: function (params, callback) {
        $.post(this.url(), params, function(data) {
          callback(data.users[0]);
        });
      },

      cameras: function (uid, callback) {
        $.getJSON(this.url(uid + '/cameras'), function(data) {
          callback(data.cameras);
        });
      }
    },

    Vendor: {
      url: function(ext){
        if (typeof(ext) === 'undefined') ext = '';
        else ext = '/' + ext;
        return window.Evercam.apiUrl + '/vendors' + ext;
      },

      all: function (callback) {
        $.getJSON(this.url(), function(data) {
          callback(data.vendors);
        });
      },

      by_mac: function (mac, callback) {
        $.getJSON(this.url(mac), function(data) {
          callback(data.vendors);
        });
      }
    },

    Camera: function (name) {
      this.data = null;
      this.timestamp = 0;
      this.endpoint = null;
      this.name = name;
      this.useProxy = false;
    }

  };

  // STREAM PLUGIN DEFINITION
  // =======================

  Evercam.Camera.url = function (ext) {
    if (typeof(ext) === 'undefined') ext = '';
    else ext = '/' + ext;
    return window.Evercam.apiUrl + '/cameras' + ext;
  };

  Evercam.Camera.by_id = function (id) {
    var camera = new Evercam.Camera(id);
    return $.getJSON(this.url(id)).then(function (data) {
      camera.data = data.cameras[0]
      return camera;
    });
  };

  Evercam.Camera.create = function (params) {
    return $.ajax({
      type: 'POST',
      url: this.url(),
      dataType: 'json',
      data: params
    });
  }

  Evercam.Camera.prototype.update = function (field) {
    var self = this,
      newdata = self.data;
    if (typeof(field) !== 'undefined') {
      newdata = {};
      newdata[field] = self.data[field];
    }
    return $.ajax({
      type: 'PATCH',
      url: Evercam.Camera.url(self.data.id),
      dataType: 'json',
      data: newdata
    });
  };

  Evercam.Camera.prototype.fetchSnapshotData = function () {
    var self = this;
    Evercam.Camera.by_id(this.name, function(camera) {
      self.data = camera;
      self.selectEndpoint();
    })
  };

  Evercam.Camera.prototype.selectEndpoint = function () {
    var self = this;
    testForAuth(this.data.endpoints[0] + this.data.snapshots.jpg, this.data.auth.basic, function(needed) {
      self.endpoint = self.data.endpoints[0];
      self.useProxy = needed;
      self.onUp();
    });
  };

  function testForAuth(url, auth, callback) {
    if (navigator.userAgent.indexOf('Chrome') === -1 && navigator.userAgent.indexOf('Firefox') === -1) {
      // url basic auth only for chrome and firefox
      callback(true);
      return;
    }

    // Create iframe with url auth
    var authurl = url.slice(0,7) + auth.username + ':' + auth.password + '@' + url.slice(7);
    var iframe = document.createElement("iframe");
    iframe.src = authurl;

    if (iframe.attachEvent){
      iframe.attachEvent("onload", function(){
        loadImg(url, callback);
      });
    } else {
      iframe.onload = function(){
        loadImg(url, callback);
      };
    }
    $(iframe).hide();
    document.body.appendChild(iframe);

  };

  function loadImg(url, callback) {
    $("<img/>")
      .load(function() {
        callback(false);
      })
      .error(function() {
        callback(true);
      })
      .attr("src", url);
  }

  Evercam.Camera.prototype.isUp = function (callback) {
    this.onUp = callback;
  };

  Evercam.Camera.prototype.needsAuth = function (callback) {
    this.onAuth = callback;
  };

  Evercam.Camera.prototype.run = function () {
    this.fetchSnapshotData();
  }

  Evercam.Camera.prototype.imgUrl = function () {
    var uri = '';
    this.timestamp = new Date().getTime();
    if (this.useProxy) {
      uri = Evercam.proxyUrl + '?url=' +  this.endpoint + this.data.snapshots.jpg + '&auth=' + base64Encode(this.data.auth.basic.username + ":" + this.data.auth.basic.password);
    } else {
      uri = this.endpoint + this.data.snapshots.jpg;
    }
    return uri;
  };

  function base64Encode(str) {
    var CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var out = "", i = 0, len = str.length, c1, c2, c3;
    while (i < len) {
      c1 = str.charCodeAt(i++) & 0xff;
      if (i == len) {
        out += CHARS.charAt(c1 >> 2);
        out += CHARS.charAt((c1 & 0x3) << 4);
        out += "==";
        break;
      }
      c2 = str.charCodeAt(i++);
      if (i == len) {
        out += CHARS.charAt(c1 >> 2);
        out += CHARS.charAt(((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4));
        out += CHARS.charAt((c2 & 0xF) << 2);
        out += "=";
        break;
      }
      c3 = str.charCodeAt(i++);
      out += CHARS.charAt(c1 >> 2);
      out += CHARS.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
      out += CHARS.charAt(((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6));
      out += CHARS.charAt(c3 & 0x3F);
    }
    return out;
  }

  // EVERCAM PLUGIN DEFINITION
  // =======================

  $.fn.camera = function(opts) {

    // override defaults
    var settings = $.extend({
      refresh: Evercam.refresh
    }, opts);

    if (typeof(settings.name) === 'undefined') {
      throw "Camera name can't be empty";
    }

    var $img = $(this);
    var camera = new Evercam.Camera(settings.name);
    var watcher = null;

    var updateImage = function() {
      if (settings.refresh > 0) {
        watcher = setTimeout(updateImage, settings.refresh);
      }
      $("<img />").attr('src', camera.imgUrl())
        .load(function() {
          if (!this.complete || typeof this.naturalWidth == 'undefined' || this.naturalWidth == 0) {
            console.log('broken image!');
          } else {
            $img.attr('src', camera.imgUrl());
          }
        });
    }

    // check img auto refresh
    $img.on('abort', function() {
      clearTimeout(watcher);
    });

    camera.isUp(function() {
      updateImage();
    });

    camera.needsAuth(function() {
      console.log(camera.name + ' requires authorization to view');
    });

    camera.run();
    return this;

  };

  function enableEvercam() {
    $.each($('img[evercam]'), function(i, e) {
      var $img = $(e);

      var name = $img.attr('evercam');
      var refresh = Number($img.attr('refresh'));

      // ensure number
      if(isNaN(refresh)) {
        refresh = Evercam.refresh;
      }

      $img.camera({
        name: name,
        refresh: refresh
      });
    });
  };

  $(window).load(enableEvercam);

})(window, jQuery);
