import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';

export default modal.ModalController.extend({
  actions: {
    agree: function() {
      if(!this.get('agree')) { return; }
      var user = session.get('user');
      user.set('terms_agree', true);
      var _this = this;
      user.save().then(function() {
        modal.close();
      }, function(err) {
        _this.set('errored', true);
      });
    },
    logout: function() {
      session.invalidate(true);
    }
  }
});

