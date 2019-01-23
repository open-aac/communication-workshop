import Ember from 'ember';
import Route from '@ember/routing/route';

export default Route.extend({
  model: function(params) {
    return {user_id: params.user_id, code: params.code};
  },
  setupController: function(controller, model) {
    controller.set('user_id', model.user_id);
    controller.set('code', model.code);
  }
});
