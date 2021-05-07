import Ember from 'ember';
import session from '../utils/session';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import Controller from '@ember/controller';
import pages from '../utils/pages';

export default Controller.extend({
  load_category: function() {
    var _this = this;
    if(_this.get('browse.category')) {
      var cat = _this.get('browse.category');
      var list = {title: cat, category: true};
      if(cat == 'books') {
        list.title = i18n.t('shared_reading_books', "Shared Reading Books");
      } else if(cat == 'activities') {
        list.title = i18n.t('context_specific_activities', "Context-Specific Activities");         
      } else if(cat == 'other') {
        list.title = i18n.t('other_focus_word_sets', "Other Focus Word Sets");         
      }
      _this.set('list', Object.assign({}, list, {loading: true}));
      pages.all('focus', {category: cat, locale: _this.get('model.locale')}).then(function(res) {
        _this.set('list', Object.assign({}, list, {results: res, meta: res.meta}));
      }, function(err) {
        _this.set('list', Object.assign({}, list, {error: true}));
      });
    }
  }.observes('browse.category'),
  actions: {
    clear: function() {
      var _this = this;
      _this.set('list', null);
    },
    search: function() {
      var _this = this;
      var q = _this.get('search');
      var list = {title: i18n.t('search_results', "Search Results"), search: true};
      _this.set('list', Object.assign({}, list, {loading: true}));
      pages.all('focus', {q: q, locale: _this.get('model.locale')}).then(function(res) {
        _this.set('list', Object.assign({}, list, {results: res, meta: res.meta}));
      }, function(err) {
        _this.set('list', Object.assign({}, list, {error: true}));
      });
    },
    set_category: function(cat) {
      var _this = this;
      _this.set('browse', {category: cat});
    },
    new_focus: function() {
      var title = this.get('new_focus_title');
      var slug = title.toLowerCase().replace(/[^\w]+/g, '-').replace(/^\-/, '').replace(/\-$/, '');
      var id = (new Date()).getTime() + "" + Math.round((Math.random() * 999)) + "-" + slug;
      // this.route('focus', {path: '/focus/:id/:locale'});

      this.transitionToRoute('focus', id, this.get('model.locale') || 'en', {queryParams: { title: title }});

    }
  }
});
