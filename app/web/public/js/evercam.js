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

    apiUrl: 'https://www.evercam.io/v1',
    proxyUrl: 'https://cors.evercam.io/',
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
      url: function(ext) {
        if (ext === undefined) ext = '';
        else ext = '/' + ext;
        return window.Evercam.apiUrl + '/models' + ext;
      },

      all: function(callback) {
        $.getJSON(this.url(), function(data) {
          callback(data.vendors);
        });
      },

      by_vendor: function (vid) {
        return $.getJSON(this.url(vid)).then(function(data) {
          return data.vendors[0];
        });
      },

      by_model: function (vid, mid, callback) {
        return $.getJSON(this.url(vid + '/' + mid)).then(function(data) {
          return data.models[0];
        });
      }
    },

    Vendor: {
      url: function(ext) {
        if (ext === undefined) ext = '';
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
    },

    User: function (login) {
      this.data = null;
      this.login = login;
    }

  };

  // USER DEFINITION
  // ====

  Evercam.User.url = function(ext) {
    if (ext === undefined) ext = '';
    else ext = '/' + ext;
    return Evercam.apiUrl + '/users' + ext;
  };

  Evercam.User.create = function (params, callback) {
    $.post(this.url(), params, function(data) {
      callback(data.users[0]);
    });
  };

  Evercam.User.cameras = function (uid, callback) {
    $.getJSON(this.url(uid + '/cameras'), function(data) {
      callback(data.cameras);
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

  Evercam.Camera.url = function (ext) {
    if (ext === undefined) ext = '';
    else ext = '/' + ext;
    return window.Evercam.apiUrl + '/cameras' + ext;
  };

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
      url: Evercam.Camera.url(id),
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

  Evercam.Camera.prototype.fetchSnapshotData = function () {
    var self = this;
    Evercam.Camera.by_id(this.name)
    .then(function(camera) {
      self.data = camera.data;
      self.selectEndpoint();
    });
  };

  Evercam.Camera.prototype.selectEndpoint = function () {
    var self = this,
      tests = [];
    $.each(self.data.endpoints, function(i, val) {
      if (self.data.snapshots && self.data.auth) {
        tests.push(testForAuth(val + self.data.snapshots.jpg, self.data.auth.basic))
      }
    });
    $.when.apply($, tests).then(function() {
      var objects = arguments;
      self.useProxy = true;
      $.each(objects, function(i, val) {
        if (self.useProxy) self.endpoint = self.data.endpoints[i];
        if (val === false && self.useProxy) {
          self.endpoint = self.data.endpoints[i];
          self.useProxy = false;
        }
      });
      self.onUp();
    });
  };

  function testForAuth(url, auth) {
    var d = new $.Deferred();
    if (navigator.userAgent.indexOf('Chrome') === -1 && navigator.userAgent.indexOf('Firefox') === -1) {
      // url basic auth only for chrome and firefox
      d.resolve(true);
      return d.promise();
    }

    // Always use proxy on https
    if (location.protocol === 'https:') {
      d.resolve(true);
      return d.promise();
    }

    // Create iframe with url auth
    var authurl = url.slice(0, 7) + auth.username + ':' + auth.password + '@' + url.slice(7),
      iframe = document.createElement("iframe");
    iframe.src = authurl;

    if (iframe.attachEvent) {
      iframe.attachEvent("onload", function() {
        loadImg(url)
        .done(function(result) {
          d.resolve(result);
        });
      });
    } else {
      iframe.onload = function() {
        loadImg(url)
        .done(function(result) {
          d.resolve(result);
        });
      };
    }
    $(iframe).hide();
    document.body.appendChild(iframe);
    return d.promise();
  }

  function loadImg(url) {
    var d = new $.Deferred();
    $("<img/>")
      .load(function() {
        d.resolve(false);
      })
      .error(function() {
        d.resolve(true);
      })
      .attr("src", url);
    return d.promise();
  }

  Evercam.Camera.prototype.isUp = function (callback) {
    this.onUp = callback;
  };

  Evercam.Camera.prototype.needsAuth = function (callback) {
    this.onAuth = callback;
  };

  Evercam.Camera.prototype.run = function () {
    this.fetchSnapshotData();
  };

  Evercam.Camera.prototype.imgUrl = function () {
    var uri = '',
      baseUrl = this.endpoint;
    if (!baseUrl) return '';
    if (baseUrl.indexOf('/', baseUrl.length - 1) !== -1 || this.data.snapshots.jpg.indexOf('/') === 0) {
      baseUrl = baseUrl + this.data.snapshots.jpg;
    } else {
      baseUrl = baseUrl + '/' + this.data.snapshots.jpg;
    }
    this.timestamp = new Date().getTime();
    if (this.useProxy) {
      uri = Evercam.proxyUrl + '?url=' +  baseUrl + '&auth=' + base64Encode(this.data.auth.basic.username + ":" + this.data.auth.basic.password);
    } else {
      uri = baseUrl;
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

    if (settings.name === undefined) {
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
          if (!this.complete || this.naturalWidth === undefined || this.naturalWidth === 0) {
            console.log('broken image!');
          } else {
            $img.attr('src', camera.imgUrl());
          }
        });
    };

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
      if (isNaN(refresh)) {
        refresh = Evercam.refresh;
      }

      $img.camera({
        name: name,
        refresh: refresh
      });
    });
  }

  $(window).load(enableEvercam);

})(window, jQuery);
