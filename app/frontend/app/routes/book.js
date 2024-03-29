import Ember from 'ember';
import Route from '@ember/routing/route';

var loc = null;
export default Route.extend({
  model: function(params) {
    loc = params.locale;
    return this.store.findRecord('book', params.id).then(function(res) {
      if(!res.get('permissions')) {
        return res.reload();
      } else {
        return res;
      }
    });
  },
  setupController: function(controller, model) {
    if(!model.get('locale')) {
      model.set('locale', loc);
    }
    controller.set('status', null);
    controller.set('model', model);
    if(model.get('pending')) { controller.set('editing', true); }
  }
});
