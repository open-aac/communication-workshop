import Ember from 'ember';
import session from '../utils/session';

export default Ember.Controller.extend({
  load_user: function() {
    var _this = this;
    if(!_this.get('user.id')) {
      session.set('user', {loading: true});
      _this.store.findRecord('user', 'self').then(function(u) {
        session.set('user', u);
      }, function(err) {
        session.set('user', {error: true});
      });
    }
  },
  actions: {
    logout: function() {
      session.invalidate(true);
    }
  }
});
