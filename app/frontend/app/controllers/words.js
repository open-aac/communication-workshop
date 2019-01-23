import Ember from 'ember';
import pages from '../utils/pages';
import Controller from '@ember/controller';

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
  actions: {
  }
});

