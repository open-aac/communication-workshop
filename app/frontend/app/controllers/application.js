import Ember from 'ember';
import session from '../utils/session';

export default Ember.Controller.extend({
  actions: {
    logout: function() {
      session.invalidate(true);
    }
  }
});
