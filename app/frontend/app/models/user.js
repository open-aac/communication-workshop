import Ember from 'ember';
import DS from 'ember-data';
import session from '../utils/session';

var User = DS.Model.extend({
  didLoad: function() {
    this.set('session', session);
  },
  user_name: DS.attr('string'),
  name: DS.attr('string'),
  admin: DS.attr('boolean'),
  created: DS.attr('date'),
  permissions: DS.attr('raw'),
  current_words: DS.attr('raw'),
  external_tracking: DS.attr('boolean'),
  external_account: DS.attr('string'),
  modeling_level: DS.attr('string'),
  focus_length: DS.attr('string'),
  starred_activity_ids: DS.attr('raw'),
  words: DS.attr('raw'),
  old_password: DS.attr('string'),
  password: DS.attr('string'),
  email: DS.attr('string'),
  url: DS.attr('string'),
  terms_agree: DS.attr('boolean'),
  word_map: DS.attr('raw'),
  map_current_words: function() {
    var map = session.get('user.full_word_map') || [];
    (this.get('current_words') || []).forEach(function(word) {
      if(map[word.locale] && map[word.locale][word.word] && map[word.locale][word.word].image && map[word.locale][word.word].image.image_url) {
        Ember.set(word, 'best_image_url', map[word.locale][word.word].image.image_url);
      }
    });
  }.observes('current_words', 'session.user.full_word_map'),
  load_map: function(force) {
    var _this = this;
    if(this.get('full_word_map') && !force) {
      return Ember.RSVP.resolve(this.get('full_word_map'));
    } else if(this.get('pending_promise')) {
      return this.get('pending_promise');
    }
    var promise = session.ajax('/api/v1/users/' + this.get('id') + '/word_map', {type: 'GET'}).then(function(res) {
      _this.set('full_word_map', res);
      _this.set('pending_promise', null);
      return res;
    }, function(err) {
      _this.set('pending_promise', null);
      return Ember.RSVP.reject(err);
    });
    _this.set('pending_promise', promise);
    return promise;
  },
  set_pending_words: function() {
    var res = this.get('word_data') || {};
    var _this = this;
    _this.set('pending_words', (res.words || []).join('\n'));
  },
  set_pending_word_map: function() {
    var res = this.get('word_data') || {};
    var _this = this;
    var map_list = [];
    for(var locale in (res.word_map || {})) {
      var word_map = res.word_map[locale] || {};
      for(var idx in word_map) {
        if(word_map[idx]) {
          var btn = Ember.$.extend({}, word_map[idx])
          btn.locale = btn.locale || locale;
          btn.sort_label = (btn.label || 'zzzzz').toLowerCase();
          map_list.push(btn);
        }
      }
    }
    map_list = map_list.sortBy('sort_label');
    _this.set('pending_word_map', map_list);
  },
  load_words: function(force) {
    var _this = this;
    if(this.get('word_data') && !force) {
      return Ember.RSVP.resolve(this.get('word_data'));
    } else if(this.get('pending_words_promise')) {
      return this.get('pending_words_promise');
    }
    var promise = session.ajax('/api/v1/users/' + this.get('id') + '/words', {type: 'GET'}).then(function(res) {
      _this.set('word_data', res);
      _this.set_pending_words();
      _this.set_pending_word_map();
      _this.set('pending_words_promise', null);
      return res;
    }, function(err) {
      _this.set('pending_words_promise', null);
      return Ember.RSVP.reject(err);
    });
    _this.set('pending_words_promise', promise);
    return promise;
  },
  check_user_name: function() {
    if(!this.get('id')) {
      var user_name = this.get('user_name');
      var user_id = this.get('id');
      this.set('user_name_check', null);
      if(user_name && user_name.length > 2) {
        var _this = this;
        _this.set('user_name_check', {checking: true});
        this.store.queryRecord('user', {existing_id: user_name}).then(function(u) {
          if(u && user_name == _this.get('user_name') && u.get('id') != user_id) {
            _this.set('user_name_check', {exists: true});
          } else {
            _this.set('user_name_check', {exists: false});
          }
        }, function() {
          if(user_name == _this.get('user_name')) {
           _this.set('user_name_check', {exists: false});
          }
          return Ember.RSVP.resolve();
        });
      }
    }
  }.observes('id', 'user_name')
});

export default User;


