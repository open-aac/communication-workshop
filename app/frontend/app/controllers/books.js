import Ember from 'ember';
import modal from '../utils/modal';
import pages from '../utils/pages';
import i18n from '../utils/i18n';
import Controller from '@ember/controller';

export default Controller.extend({
  load_books: function() {
    var _this = this;
    _this.set('books', {loading: true});
    pages.all('book', {}).then(function(books) {
      _this.set('books', books);
    }, function(err) {
      _this.set('books', {error: true});
    });
  },
  actions: {
    new_book: function() {
      var title = this.get('new_book_title');
      var slug = title.toLowerCase().replace(/[^\w]+/g, '-').replace(/^\-/, '').replace(/\-$/, '');
      var id = (new Date()).getTime() + "" + Math.round((Math.random() * 999)) + "-" + slug;
      this.transitionToRoute('book', id, {queryParams: { title: title }});
    }
  }
});
