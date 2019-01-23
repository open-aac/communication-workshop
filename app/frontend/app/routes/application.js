import Ember from 'ember';
import modal from '../utils/modal';
import session from '../utils/session';
import Route from '@ember/routing/route';
import $ from 'jquery';

export default Route.extend({
  setupController: function(controller, model) {
    controller.load_user();
    modal.setup(this);
  },
  actions: {
    willTransition: function() {
      modal.close();
    },
    didTransition: function() {
      $(window).scrollTop(0);
    }
  }
});
