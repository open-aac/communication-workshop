import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';

export default Ember.Controller.extend({
  actions: {
    new_book: function() {
      var title = this.get('new_book_title');
      var slug = title.toLowerCase().replace(/[^\w]+/g, '-').replace(/^\-/, '').replace(/\-$/, '');
      var id = (new Date()).getTime() + "" + Math.round((Math.random() * 999)) + "-" + slug;
      this.transitionToRoute('book', id, {queryParams: { title: title }});
    }
  }
});
