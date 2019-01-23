import Ember from 'ember';
import Route from '@ember/routing/route';

export default Route.extend({
  setupController: function(controller, model) {
    controller.set('status', null);
    controller.set('editing', null);
    controller.set('edited', null);
    controller.set('model', model);
    controller.set('model.defaults_loaded', null);
  }
});
