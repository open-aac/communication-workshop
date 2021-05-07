import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import Controller from '@ember/controller';
import { later } from '@ember/runloop';
import { htmlSafe } from '@ember/template';
import { get as emberGet, set as emberSet } from '@ember/object';
import session from '../utils/session';

export default Controller.extend({
  queryParams: ['title'],
  editable: function() {
    return this.get('model.pending') || this.get('editing') || this.get('model.permissions.edit');
  }.property('model.pending', 'editing', 'model.permissions.edit'),
  set_image_url: function() {
    // <!-- http://images.amazon.com/images/P/0142402753.01._SCLZZZZZZZ_.jpg 
    // var url = "http://www.amazon.com/Kindle-Wireless-Reading-Display-Generation/dp/B0015T963C";
    // 
    // m = url.match(regex);
    // -->
    var source = this.get('model.source_url');
    if(source && !this.get('image_url')) {
      var regex = RegExp("http://www.amazon.com/([\\w-]+/)?(dp|gp/product|exec/obidos/asin)/(\\w+/)?([A-Z0-9]{10})");
      var match = source.match(regex);
      if(match && match[4]) {
        this.set('model.image_url', "http://images.amazon.com/images/P/" + match[4] + ".01._SCLZZZZZZZ_.jpg")
      }
    }
  }.observes('model.source_url', 'model.image_url'),
  update_found_words: function() {
    var _this = this;
    var loc = (session.get('user.full_word_map') || {})[_this.get('model.locale')];
    var found = [];
    var all_found_words = {};
    if(!_this.get('model.all_words')) { return; }
    var words = (_this.get('model.all_words') || []).split(/\s+/);
    if(loc) {
      var spaces = [];
      for(var key in loc) {
        if(key.match(/\s/)) {
          spaces.push(loc[key]);
        }
      }
      words.forEach(function(word, idx) {
        if(loc[word]) {
          found.push(loc[word]);
          all_found_words[word] = true;
        }
        var lookahead = words.slice(idx, idx + 5).join(' ');
        spaces.forEach(function(ref) {
          if(lookahead.indexOf(ref.word) == 0) {
            found.push(ref);
            ref.word.split(/\s+/).forEach(function(s) {
              all_found_words[s] = true;
            })
          }
        });
      });
    }
    var res = [];
    found.forEach(function(word) {
      res.push(Object.assign({}, word, {label: word.word, image_url: word.image.image_url}));
    });
    this.set('found_words', res);
    var missing = [];
    words.forEach(function(word) {
      if(!all_found_words[word]) {
        missing.push(word);
      }
    });
    this.set('missing_words', missing);
  }.observes('model.all_words', 'model.locale', 'session.user.full_word_map'),
  any_collapsed: function() {
    return this.get('found_words').find(function(w) { return emberGet(w, 'collapsed'); });
  }.property('found_words.@each.collapsed'),
  category_types: function() {
    var res = [
      {name: i18n.t('choose_category', "[ Choose Category ]"), id: "none"},
      {name: i18n.t('shared_reading_books', "Shared Reading Books"), id: "books"},
      {name: i18n.t('context_specific_activities', "Context-Specific Activities"), id: "activities"},
      {name: i18n.t('other_focus_word_sets', "Other Focus Word Sets"), id: "other"},
    ];
    return res;
  }.property(),
  actions: {
    edit: function() {
      this.set('editing', true);
    },
    save: function() {
      var _this = this;
      _this.set('status', {saving: true});
      if(!_this.get('model.category') || _this.get('model.category') == 'none') {
        _this.set('model.category', 'other');
      }
      _this.get('model').save().then(function() {
        _this.set('status', null);
        _this.set('editing', false);
      }, function() {
        _this.set('status', {error: true});
      });
    },
    cancel: function() {
      if(this.get('model.pending')) {
        this.transitionToRoute('focus', this.get('model.locale') || 'en');
      } else {
        this.get('model').rollbackAttributes();
        this.set('editing', false);
      }
    },
    approve: function() {
      var _this = this;
      _this.set('model.approved', true);
      _this.set('approval', {pending: true});
      _this.get('model').save().then(function() {
        _this.set('approval', null);
      }, function() {
        _this.set('approval', {error: true});
      });
    },
    toggle: function(word) {
      emberSet(word, 'collapsed', !emberGet(word, 'collapsed'));
      if(emberGet(word, 'collapsed')) {
        var style = "color: #000; display: inline-block; padding: 5px 10px; margin-right: 5px; border-radius: 5px;";
        style = style + "border: 2px solid " + (emberGet(word, 'border_color') || '#888') + ";";
        style = style + "background: " + (emberGet(word, 'background_color') || '#fff') + ";";
        emberSet(word, 'collapsed_style', htmlSafe(style));
      }
    }
  }
});
