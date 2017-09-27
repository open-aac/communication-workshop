import Ember from 'ember';

export default Ember.Route.extend({
  model: function(params) {
    return this.store.findRecord('user', params.user_id).then(function(res) {
      if(!res.get('permissions')) {
        return res.reload();
      } else {
        return res;
      }
    });
  },
  setupController: function(controller, model) {
    model.load_words();
    controller.set('model', model);
    controller.setup();
  }
});
