import Ember from 'ember';
import Route from '@ember/routing/route';

export default Route.extend({
  model: function(params) {
    return {locale: params.locale};
  },
  setupController: function(controller, model) {
    controller.set('locale', model.locale);
  }
});
