import Ember from 'ember';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    controller.load_words();
    controller.load_categories();
    controller.load_report();
  }
});
