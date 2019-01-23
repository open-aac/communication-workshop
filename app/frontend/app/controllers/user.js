import Ember from 'ember';
import session from '../utils/session';
import i18n from '../utils/i18n';
import Controller from '@ember/controller';
import { set as emberSet } from '@ember/object';
import { htmlSafe } from '@ember/template';

export default Controller.extend({
  setup: function() {
    this.set('editing', false);
    this.set('update_status', null);
  },
  keyed_colors: function() {
    return [
      {"border":"#ccc","fill":"#fff","color":"White","types":["conjunction"],"style":htmlSafe("border-color: #ccc; background: #fff;")},
      {"border":"#dd0","fill":"#ffa","color":"Yellow","hint":"people","types":["pronoun"],"style":htmlSafe("border-color: #dd0; background: #ffa;")},
      {"border":"#6d0","fill":"#cfa","color":"Green","hint":"actions","types":["verb"],"style":htmlSafe("border-color: #6d0; background: #cfa;")},
      {"fill":"#fca","color":"Orange","hint":"nouns","types":["noun","nominative"],"border":"#ff7011","style":htmlSafe("border-color: #ff7011; background: #fca;")},
      {"fill":"#acf","color":"Blue","hint":"describing words","types":["adjective"],"border":"#1170ff","style":htmlSafe("border-color: #1170ff; background: #acf;")},
      {"fill":"#caf","color":"Purple","hint":"questions","types":["question"],"border":"#7011ff","style":htmlSafe("border-color: #7011ff; background: #caf;")},
      {"fill":"#faa","color":"Red","hint":"negations","types":["negation","expletive","interjection"],"border":"#ff1111","style":htmlSafe("border-color: #ff1111; background: #faa;")},
      {"fill":"#fac","color":"Pink","hint":"social words","types":["preposition"],"border":"#ff1170","style":htmlSafe("border-color: #ff1170; background: #fac;")},
      {"fill":"#ca8","color":"Brown","hint":"adverbs","types":["adverb"],"border":"#835d38","style":htmlSafe("border-color: #835d38; background: #ca8;")},
      {"fill":"#ccc","color":"Gray","hint":"determiners","types":["article","determiner"],"border":"#808080","style":htmlSafe("border-color: #808080; background: #ccc;")}
    ];
  }.property(),
  modeling_levels: function() {
    var res = [
      {name: i18n.t('one_button', "1-word communication"), id: "1"},
      {name: i18n.t('two_three_buttons', "2-3 word communication"), id: "2"},
      {name: i18n.t('three_plus_buttons', "4+ word communication"), id: "3"},
    ];
    return res;
  }.property(),
  modeling_lengths: function() {
    var res = [
      {name: i18n.t('one_month', "1 month"), id: "30"},
      {name: i18n.t('two_weeks', "2 weeks"), id: "14"},
      {name: i18n.t('one_week', "1 week"), id: "7"},
      {name: i18n.t('two months', "2 months"), id: "60"},
      {name: i18n.t('three months', "3 months"), id: "90"},
    ];
    return res;
  }.property(),
  password_mismatch: function() {
    return (this.get('model.password') || this.get('password2')) && this.get('model.password') != this.get('password2');
  }.property('model.password', 'password2'),
  save_disabled: function() {
    if(this.get('status.saving')) {
      return true;
    } else if(this.get('resetting_password')) {
      return !this.get('model.password') || !this.get('password2') || this.get('model.password') != this.get('password2');
    }
  }.property('status.saving', 'resetting_password', 'model.password', 'password2'),
  actions: {
    edit: function() {
      this.set('editing', true);
      this.set('editing_words', false);
      this.set('editing_word_map', false);
    },
    cancel: function() {
      this.get('model').rollbackAttributes();
      this.set('editing', false);
    },
    save: function() {
      var _this = this;
      if(_this.get('editing_words')) {
        _this.set('model.words', _this.get('model.pending_words').split(/\n/));
      }
      if(_this.get('editing_word_map')) {
        var map = {};
        (_this.get('model.pending_word_map') || []).forEach(function(button) {
          button.locale = button.locale || 'en';
          map[button.locale] = map[button.locale] || {};
          map[button.locale][button.label] = button;
        });
        _this.set('model.word_map', map);
      }
      _this.set('status', {saving: true});
      _this.get('model').save().then(function(res) {
        _this.set('status', null);
        _this.set('model.words', null);
        _this.set('model.pending_words', null);
        _this.set('model.pending_word_map', null);
        _this.set('editing', false);
        _this.get('model').load_words(true);
        _this.get('model').load_map();
      }, function(err) {
        _this.set('status', {error: true});
      });
    },
    edit_words: function() {
      this.get('model').set_pending_words();
      this.set('editing_words', true);
    },
    edit_word_map: function() {
      this.get('model').set_pending_word_map();
      this.set('editing_word_map', true);
    },
    cancel_edit_words: function() {
      this.set('editing_words', false);
    },
    cancel_edit_word_map: function() {
      this.set('editing_word_map', false);
    },
    add_button: function() {
      this.set('model.pending_word_map', this.get('model.pending_word_map') || []);
      this.get('model.pending_word_map').pushObject({});
    },
    update_image: function(image, ref) {
      if(ref) {
        emberSet(ref, 'image', image);
        emberSet(ref, 'image_url', image.image_url);
      }
    },
    color: function(button, color) {
      emberSet(button, 'background_color', color.fill);
      emberSet(button, 'border_color', color.border);
    },
    update_word_map: function() {
      var _this = this;
      _this.set('update_status', {loading: true});
      session.ajax('/api/v1/users/' + _this.get('model.id') + '/update_word_map', {type: 'POST'}).then(function(res) {
        _this.get('model').load_map(true).then(function(res) {
          _this.set('update_status', {updated: true});
        }, function(err) {
          _this.set('update_status', {error: true});
        });
      }, function(err) {
        _this.set('update_status', {error: true});
      });
    },
    reset_password: function() {
      this.set('resetting_password', true);
    }
  }
});
