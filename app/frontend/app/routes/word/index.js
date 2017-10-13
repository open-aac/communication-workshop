import Ember from 'ember';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    controller.set('status', null);
    controller.set('editing', null);
    controller.set('model', model);
  }
});
