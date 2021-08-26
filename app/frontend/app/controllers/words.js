import Ember from 'ember';
import pages from '../utils/pages';
import Controller from '@ember/controller';
import session from '../utils/session';
import { set as emberSet } from '@ember/object';

export default Controller.extend({
  load_words: function() {
    var _this = this;
    _this.set('filter', null);
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
  filtered_words: function() {
    var res = [];
    var filter = this.get('filter');
    if(!(this.get('words') || []).forEach) { return res; }
    (this.get('words') || []).forEach(function(w) {
      if(filter == 'all' && !filter) {
        res.push(w);
      } else if(filter == 'pending' && w.get('pending_revisions')) {
        res.push(w);
      } else if(filter == 'unapproved' && !w.get('has_baseline_content')) {
        res.push(w);
      }
    });
    return res;
  }.property('words', 'filter'),
  word_counts: function() {
    var res = {
      total: 0,
      pending: 0,
      unapproved: 0
    }
    if(!(this.get('words') || []).forEach) { return res; }
    (this.get('words') || []).forEach(function(w) {
      if(session.is_admin() || w.get('has_baseline_content')) {
        res.total++;
      }
      if(!w.get('has_baseline_content')) {
        res.unapproved++;
      }
      if(w.get('pending_revisions')) {
        res.pending++;
      }
    });
    return res;
  }.property('words', 'words.@each.has_baseline_content', 'session.is_admin'),  
  update_availability: function() {
    if(!(this.get('words') || []).forEach) { return; }
    if(!session.is_admin()) {
      (this.get('words') || []).forEach(function(item) {
        item.set('unavailable', !item.get('has_baseline_content'));
      });
    }
  }.observes('words', 'words.@each.has_baseline_content', 'session.is_admin'),
  actions: {
    filter: function(f) {
      this.set('filter', f);
    }
  }
});

