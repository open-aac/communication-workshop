import Ember from 'ember';
import Route from '@ember/routing/route';

export default Route.extend({
  setupController: function(controller, model) {
    controller.load_words(false);
    controller.load_missing_words(false);
    controller.load_categories(false);
    controller.load_report();
  }
});
