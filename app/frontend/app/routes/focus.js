import Ember from 'ember';
import Route from '@ember/routing/route';
import session from '../utils/session';

var loc = null;
var title = null;
export default Route.extend({
  model: function(params) {
    loc = params.locale;
    title = params.title;
    return this.store.findRecord('focus', params.id).then(function(res) {
      if(!res.get('permissions')) {
        return res.reload();
      } else {
        return res;
      }
    });
  },
  setupController: function(controller, model) {
    controller.set('status', null);
    if(!model.get('locale')) {
      model.set('locale', loc);
    }
    if(!model.get('title')) {
      model.set('title', title);
    }
    controller.set('model', model);
    if(model.get('pending')) { controller.set('editing', true); }
  }
});
