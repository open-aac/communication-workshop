import Ember from 'ember';
import modal from '../utils/modal';
import pages from '../utils/pages';
import Controller from '@ember/controller';

export default Controller.extend({
  load_categories: function() {
    var _this = this;
    _this.set('categories', {loading: true});
    pages.all('category', {sort: 'alpha'}).then(function(res) {
      _this.set('categories', res);
    }, function() {
      _this.set('categories', {error: true});
    });
  },
  actions: {
  }
});

