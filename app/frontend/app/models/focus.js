import Ember from 'ember';
import DS from 'ember-data';

var Focus = DS.Model.extend({
  didLoad: function() {
  },
  locale: DS.attr('string'),
  pending: DS.attr('boolean'),
  permissions: DS.attr('raw'),
  title: DS.attr('string'),
  author: DS.attr('string'),
  category: DS.attr('string'),
  words: DS.attr('string'),
  all_words: DS.attr('string'),
  image_url: DS.attr('string'),
  source_url: DS.attr('string'),
  helper_words: DS.attr('string'),
  approved_users: DS.attr('raw'),
  all_words_capitalized: function() {
    return (this.get('all_words') || '').replace(/\bi\b/g, 'I');
  }.property('all_words')
});

export default Focus;
