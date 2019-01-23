import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';
import Controller from '@ember/controller';

export default Controller.extend({
  bad_password: function() {
    return this.get('password') && this.get('password').length > 0 && this.get('password').length < 6;
  }.property('password'),
  no_submit: function() {
    return this.get('bad_password') || this.get('status.attempting');
  }.property('status.attempting', 'bad_password'),
  actions: {
    reset: function() {
      var _this = this;
      _this.set('status', {attempting: true});
      session.ajax('/api/v1/users/' + _this.get('user_id') + '/password_reset', {
        type: 'POST',
        data: {
          token: _this.get('code'),
          password: _this.get('password')
        }
      }).then(function(res) {
        if(res.reset) {
          _this.set('status', {reset: true});
        } else {
          _this.set('status', {mismatch: true});
        }
      }, function(err) {
        _this.set('status', {error: true});
      });
    }
  }
});
