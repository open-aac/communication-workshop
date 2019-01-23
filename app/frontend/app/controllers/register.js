import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';
import Controller from '@ember/controller';

export default Controller.extend({
  user_name_invalid: function() {
    return !!(this.get('model.user_name') || '').match(/[\s\.'"]/);
  }.property('model.user_name'),
  bad_password: function() {
    return this.get('model.password') && this.get('model.password').length > 0 && this.get('model.password').length < 6;
  }.property('model.password'),
  no_submit: function() {
    return this.get('bad_password') || this.get('status.attempting') || this.get('user_name_invalid') || this.get('model.user_name_check.exists');
  }.property('status.attempting', 'bad_password', 'user_name_invalid', 'model.user_name_check.exists'),
  actions: {
    register_and_login: function() {
      var _this = this;
      _this.set('status', {attempting: true});
      var pw = _this.get('model.password');
      _this.get('model').save().then(function(res) {
        res.set('password', null);
        session.authenticate({
          client_secret: 'N/A',
          identification: res.get('user_name'),
          password: pw
        }).then(function(res) {
          session.load_user();
          _this.transitionToRoute('index');
        });
      }, function(err) {
        _this.set('status', {errored: true});
      });
    }
  }
});

