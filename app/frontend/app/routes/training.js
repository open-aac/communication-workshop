import Ember from 'ember';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    controller.update_stash();
  }
});
