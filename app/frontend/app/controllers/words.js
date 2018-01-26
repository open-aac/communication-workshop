import Ember from 'ember';
import pages from '../utils/pages';

export default Ember.Controller.extend({
  load_words: function() {
    var _this = this;
    _this.set('words', {loading: true});
    pages.all('word', {sort: 'alpha'}, function(res) {
      _this.set('words', res);
    }).then(function(res) {
      _this.set('words', res);
    }, function() {
      _this.set('words', {error: true});
    });
  },
  actions: {
  }
});

