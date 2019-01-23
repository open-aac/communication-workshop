import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';
import Controller from '@ember/controller';

export default Controller.extend({
  actions: {
    login: function() {
      var _this = this;
      session.authenticate({
        client_secret: 'N/A',
        identification: this.get('user_name'),
        password: this.get('password')
      }).then(function(res) {
        session.load_user();
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

