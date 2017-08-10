import Ember from 'ember';

export default Ember.Controller.extend({
  load_words: function() {
    var _this = this;
    _this.set('words', {loading: true});
    this.store.query('word', {}).then(function(res) {
      _this.set('words', res);
    }, function() {
      _this.set('words', {error: true});
    });
  }
});
