import Ember from 'ember';

export default Ember.Route.extend({
  model: function(params) {
    return this.store.findRecord('book', params.id).then(function(res) {
      if(!res.get('permissions')) {
        return res.reload();
      } else {
        return res;
      }
    });
  },
  setupController: function(controller, model) {
    controller.set('status', null);
    controller.set('model', model);
    if(model.get('pending')) { controller.set('editing', true); }
  }
});
