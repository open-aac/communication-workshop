import Ember from 'ember';
import Route from '@ember/routing/route';

export default Route.extend({
  model: function(params) {
    return this.store.findRecord('word', params.word + ":" + params.locale).then(function(res) {
      if(!res.get('permissions')) {
        res.rollbackAttributes();
        return res.reload();
      } else {
        return res;
      }
    });
  }
});
