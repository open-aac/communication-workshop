import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import session from '../utils/session';

var controller = null;
export default modal.ModalController.extend({
  opening: function() {
    this.set('error', null);
    controller = this;
  },
  assert_auth: function(auth) {
    var _this = this;
    session.ajax('/auth/coughdrop/confirm?code=' + auth.code, {
      type: 'GET'
    }).then(function(response) {
      session.store('auth', {
        access_token: response.access_token,
        user_name: response.user_name,
        name: response.name
      });
      session.store('just_logged_in', true);
      session.restore();
      session.data_store = _this.store;
      session.load_user();
      modal.close('coughdrop-login');
      _this.transitionToRoute('index');
    }, function(err) {
      _this.set('error', true);
    });
  }
});

window.addEventListener('message', function(event) {
  if(event && event.data && event.data.type == 'oauth_status') {
    controller.assert_auth(event.data);
  }
});
