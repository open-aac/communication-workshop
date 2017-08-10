import Ember from 'ember';
import session from '../utils/session';

export default {
  name: 'session',
  initialize: function(app) {
    window.Ember.app = app;
    session.setup(app);
    session.restore();
  }
};
