import Ember from 'ember';
import DS from 'ember-data';

var Book = DS.Model.extend({
  didLoad: function() {
    var _this = this;
    if(!this.get('pages') && this.get('pending')) {
      this.set('pages', []);
    }
  },
  pending: DS.attr('boolean'),
  permissions: DS.attr('raw'),
  pages: DS.attr('raw'),
  image: DS.attr('raw'),
  locale: DS.attr('string'),
  related_words: DS.attr('raw'),
  total_pages: DS.attr('number'),
  title: DS.attr('string'),
  book_type: function() {
    return "communication_workshop";
  }.property(),
  author: DS.attr('string'),
  new_core_words: DS.attr('string'),
});

export default Book;
