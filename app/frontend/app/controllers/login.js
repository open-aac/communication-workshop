import Ember from 'ember';
import session from '../utils/session';

export default Ember.Controller.extend({
  actions: {
    login: function() {
      var _this = this;
      session.authenticate({
        client_secret: 'N/A',
        identification: this.get('user_name'),
        password: this.get('password')
      }).then(function(res) {
        _this.transitionToRoute('index');
      });
    }
  }
});

