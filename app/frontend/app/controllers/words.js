import Ember from 'ember';
import pages from '../utils/pages';
import Controller from '@ember/controller';
import session from '../utils/session';
import { set as emberSet } from '@ember/object';

export default Controller.extend({
  load_words: function() {
    var _this = this;
    _this.set('words', {loading: true});
    var append = function(results) {
      var list = _this.get('words');
      if(!_this.get('words.length')) {
        list = [];
        _this.set('words', list);
      }
      results.forEach(function(word) {
        if(!list.find(function(w) { return w.get('id') == word.get('id'); })) {
          list.pushObject(word);
        }
      });
    };
    pages.all('word', {sort: 'alpha'}, function(res) {
      append(res);
    }).then(function(res) {
      append(res);
    }, function() {
      _this.set('words', {error: true});
    });
  },
  update_availability: function() {
    if(!session.get('is_admin')) {
      (this.get('list.results') || []).forEach(function(item) {
        item.set('unavailable', !item.get('has_baseline_content'));
      });
    }
  }.observes('list.results.@each.has_baseline_content', 'session.is_admin'),
  actions: {
  }
});

