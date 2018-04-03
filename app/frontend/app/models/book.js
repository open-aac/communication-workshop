import Ember from 'ember';
import DS from 'ember-data';

var Book = DS.Model.extend({
  didLoad: function() {
    var _this = this;
    if(!this.get('pages')) {
      this.set('pages', []);
    }
  },
  pending: DS.attr('boolean'),
  pages: DS.attr('raw'),
  image: DS.attr('raw'),
  title: DS.attr('string'),
  author: DS.attr('string'),
  new_core_words: DS.attr('string'),
});

export default Book;
