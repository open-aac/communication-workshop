import Ember from 'ember';

var cache = null;
var session = Ember.Object.extend({
  tokens: {},
  setup: function(application) {
    application.register('learn_aac:session', session, { instantiate: false, singleton: true });
    Ember.$.each(['model', 'controller', 'view', 'route'], function(i, component) {
      application.inject(component, 'session', 'learn_aac:session');
    });
    Ember.session = session;
  },
  store: function(key, val) {
    var res = JSON.parse(localStorage['app_session'] || "{}") || {};
    if(!cache) {
      cache = res;
    }
    res[key] = val;
    cache[key] = val;
    localStorage['app_session'] = JSON.stringify(res);
    return true;
  },
  retrieve: function(key, val) {
    if(cache) {
      return cache[key];
    }
    var res = JSON.parse(localStorage['app_session'] || "{}") || {};
    cache = res;
    return res[key];
  },
  clear: function() {
    localStorage['app_session'] = null;
    cache = null;
  },
  ajax: function(url, opts) {
    var data = session.retrieve('auth') || {};
    if(url.match && url.match(/^http/)) {
      return realAjax(url, opts);
    }
    if(url.toString() === url) {
      opts = opts || {};
      opts.url = url;
    } else {
      opts = url;
    }
    if(data && data.access_token) {
      opts.headers = opts.headers || {};
      opts.headers['Authorization'] = 'Bearer ' + data.access_token;
    }
    return realAjax(opts);
  },
  authenticate: function(credentials) {
    var _this = this;
    var res = new Ember.RSVP.Promise(function(resolve, reject) {
      var data = {
        grant_type: 'password',
        client_id: 'browser',
        client_secret: credentials.client_secret,
        username: credentials.identification,
        password: credentials.password
      };

      Ember.$.ajax('/token', {method: 'POST', data: data}).then(function(response) {
        Ember.run(function() {
          session.store('auth', {
            access_token: response.access_token,
            user_name: response.user_name,
            name: response.name
          });
          session.store('just_logged_in', true);
          session.restore();
          resolve(response);
        });
      }, function(data) {
        var xhr = data.fakeXHR || {};
        Ember.run(function() {
          reject(xhr.responseJSON || xhr.responseText);
        });
      });
    });
    res.then(null, function() { });
    return res;
  },
  check_token: function(allow_invalidate) {
    var store_data = session.retrieve('auth') || {};
    var key = store_data.access_token || "none";
    session.tokens = session.tokens || {};
    session.tokens[key] = true;
    var url = '/api/v1/token_check?access_token=' + store_data.access_token;
    if(store_data.as_user_id) {
      url = url + "&as_user_id=" + store_data.as_user_id;
    }
    return Ember.$.ajax(url, {
      type: 'GET'
    }).then(function(data) {
      if(data.authenticated !== true) {
        session.set('invalid_token', true);
        if(allow_invalidate) {
          session.invalidate(true);
        }
      } else {
        session.set('invalid_token', false);
      }
      if(data.user_name) {
        session.set('user_name', data.user_name);
      }
      if(data.name) {
        session.set('name', data.name);
      }
      if(data.meta && data.meta.fakeXHR && data.meta.fakeXHR.browserToken) {
        session.set('browserToken', data.meta.fakeXHR.browserToken);
      }
      return Ember.RSVP.resolve({browserToken: session.get('browserToken')});
    }, function(data) {
      if(data && data.responseJSON) { data = data.responseJSON; }
      if(!session.get('online')) {
        return;
      }
      if(data && data.error && data.invalid_token) {
        session.set('invalid_token', true);
        if(allow_invalidate) {
          session.invalidate(true);
        }
      }
      if(data && data.fakeXHR && data.fakeXHR.browserToken) {
        session.set('browserToken', data.fakeXHR.browserToken);
      }
      if(data && data.result && data.result.error == "not online") {
        return;
      }
      session.tokens[key] = false;
      return Ember.RSVP.resolve({browserToken: session.get('browserToken')});
    });
  },
  restore: function(force_check_for_token) {
    var store_data = session.retrieve('auth') || {};
    var key = store_data.access_token || "none";
    session.tokens = session.tokens || {};
    if(store_data.access_token && !session.get('isAuthenticated')) {
      session.set('isAuthenticated', true);
      session.set('access_token', store_data.access_token);
      session.set('user_name', store_data.user_name);
      session.set('name', store_data.name);
      session.set('as_user_id', store_data.as_user_id);
    } else if(!store_data.access_token) {
      session.invalidate();
    }
    if(force_check_for_token || (session.tokens[key] == null && !Ember.testing && session.get('online'))) {
      if(store_data.access_token || force_check_for_token) {
        session.check_token(true);
      } else {
        session.set('tokenConfirmed', false);
      }
    }

    return store_data;
  },
  load_user: function() {
    if(!session.data_store) { return; }
    session.set('user', {loading: true});
    session.data_store.findRecord('user', 'self').then(function(u) {
      u.load_map();
      session.set('user', u);
    }, function(err) {
      session.set('user', {error: true});
    });
  },
  override: function(options) {
    var data = session.restore();
    data.access_token = options.access_token;
    data.user_name = options.user_name;
    data.name = options.name;
    session.clear();
    session.store('auth', data);

    session.reload('/');
  },
  reload: function(path) {
    if(path) {
      if(Ember.testing) {
        console.error("would have redirected off the page");
      } else {
        location.href = path;
      }
    } else {
      location.reload();
    }
  },
  invalidate: function() {
    var full_invalidate = session.retrieve('auth');
    session.clear();
    if(full_invalidate) {
      session.reload('/');
    }
    var _this = this;
    Ember.run.later(function() {
      session.set('isAuthenticated', false);
      session.set('access_token', null);
      session.set('user_name', null);
      session.set('name', null);
      session.set('as_user_id', null);
    });
  }
}).create({
  online: navigator.onLine
});
window.session = session;

window.addEventListener('online', function() {
  session.set('online', true);
});
window.addEventListener('offline', function() {
  session.set('online', false);
});
// Cordova notifies on the document object
document.addEventListener('online', function() {
  session.set('online', true);
});
document.addEventListener('offline', function() {
  session.set('online', false);
});

var realAjax = Ember.$.ajax;
Ember.$.ajax = function(url, opts) {
  return session.ajax(url, opts);
};


export default session;
