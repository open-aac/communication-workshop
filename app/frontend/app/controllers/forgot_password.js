import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';

export default Ember.Controller.extend({
  actions: {
    request_password: function() {
      var _this = this;
      _this.set('status', {attempting: true});
      session.ajax('/api/v1/users/password_reset', {
        type: 'POST',
        data: {
          user_name: _this.get('user_name')
        }
      }).then(function(res) {
        if(res.sent) {
          _this.set('status', {attempted: true});
        } else {
          _this.set('status', {not_found: true});
        }
      }, function(err) {
        _this.set('status', {error: true});
      });
    }
  }
});
