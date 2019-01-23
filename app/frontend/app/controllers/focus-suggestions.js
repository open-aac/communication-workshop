import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import session from '../utils/session';
import $ from 'jquery';

export default modal.ModalController.extend({
  opening: function() {
    var _this = this;
    _this.set('suggestions', {loading: true});
    var type = _this.get('model.type');
    var path = '/api/v1/words/suggestions';
    if(_this.get('model.id')) {
      path = path + '?id=' + _this.get('model.id');
    }
    session.ajax(path, {type: 'GET'}).then(function(res) {
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
        res.push($.extend({}, sug.data, {type: sug.type || _this.get('model.type')}));
      });
      return res;
    } else {
      return null;
    }
  }.property('suggestions')
});
