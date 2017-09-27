import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import session from '../utils/session';

export default modal.ModalController.extend({
  opening: function() {
    var _this = this;
    _this.set('suggestions', {loading: true});
    var type = _this.get('model.type');
    session.ajax('/api/v1/words/suggestions', {type: 'GET'}).then(function(res) {
      _this.set('suggestions', res[type]);
    }, function(err) {
      _this.set('suggestions', {error: true});
    });
  },
  mapped_suggestions: function() {
    if(this.get('suggestions.length')) {
      var res = [];
      var _this = this;
      this.get('suggestions').forEach(function(sug) {
        res.push(Ember.$.extend({}, sug.data, {type: sug.type || _this.get('model.type')}));
      });
      return res;
    } else {
      return null;
    }
  }.property('suggestions')
});
