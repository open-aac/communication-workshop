import Ember from 'ember';
import modal from '../utils/modal';
import pages from '../utils/pages';
import i18n from '../utils/i18n';
import Controller from '@ember/controller';

export default Controller.extend({
  load_books: function() {
    var _this = this;
    _this.set('books', {loading: true});
    var opts = {};
    if(this.get('search_string')) {
      opts.q = this.get('search_string');
    }
    pages.all('book', opts).then(function(books) {
      _this.set('books', books);
    }, function(err) {
      _this.set('books', {error: true});
    });
  },
  actions: {
    search: function() {
      var str = this.get('search');
      this.set('search_string', str);
      this.load_books();
    },
    clear: function() {
      this.set('search_string', null);
      this.load_books();
    },
    new_book: function() {
      var title = this.get('new_book_title');
      var slug = title.toLowerCase().replace(/[^\w]+/g, '-').replace(/^\-/, '').replace(/\-$/, '');
      var id = (new Date()).getTime() + "" + Math.round((Math.random() * 999)) + "-" + slug;
      this.transitionToRoute('book', id, {queryParams: { title: title, locale: this.get('model.locale') }});
    }
  }
});
