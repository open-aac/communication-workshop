import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';
import Controller from '@ember/controller';

export default Controller.extend({
  load_user: function() {
    var _this = this;
    if(!_this.get('user.id') && session.get('user_name')) {
      session.data_store = _this.store;
      session.load_user();
    }
  },
  clear_search_status: function() {
    this.set('search_status', null);
  }.observes('search_string'),
  assert_terms_agree: function() {
    if(this.get('session.user.id') && !this.get('session.user.terms_agree')) {
      modal.open('terms-agree');
    }
  }.observes('session.user.id', 'session.user.terms_agree'),
  actions: {
    logout: function() {
      session.invalidate(true);
    },
    search: function() {
      var q = this.get('search_string');
      var _this = this;
      _this.set('search_status', null);
      this.store.query('word', {q: q}).then(function(res) {
        if(res && res.get('firstObject')) {
          var word = res.get('firstObject');
          _this.transitionToRoute('word', word.get('word'), word.get('locale'));
        } else {
          _this.set('search_status', {none: true});
        }
      }, function() {
        _this.set('search_status', {error: true});
      });
    }
  }
});
