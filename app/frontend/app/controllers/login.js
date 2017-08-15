import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';

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
    },
    external_login: function(service) {
      if(service == 'coughdrop') {
        modal.open('coughdrop-login');
      }
    }
  }
});

