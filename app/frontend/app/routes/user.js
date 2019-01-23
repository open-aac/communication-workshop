import Ember from 'ember';
import Route from '@ember/routing/route';
import EmberObject from '@ember/object';

export default Route.extend({
  model: function(params) {
    return this.store.findRecord('user', params.user_id).then(function(res) {
      if(!res.get('permissions')) {
        return res.reload();
      } else {
        return res;
      }
    }).then(null, function() {
      return EmberObject.create({user_name: params.user_id, link: location.href.match(/link=1/)});
    });
  },
  setupController: function(controller, model) {
    controller.set('model', model);
    controller.set('resetting_password', false);
    if(model.get('id')) {
      model.load_words();
      model.set('password', null);
      model.set('old_password', null);
    }
    controller.setup();
  }
});
