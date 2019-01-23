import Ember from 'ember';
import Route from '@ember/routing/route';

export default Route.extend({
  setupController: function(controller, model) {
    controller.set('model', controller.store.createRecord('user'));
  }
});
