import Ember from 'ember';
import DS from 'ember-data';

var Category = DS.Model.extend({
  didLoad: function() {
    var _this = this;
    ['level_1_modeling_examples', 'level_2_modeling_examples', 'level_3_modeling_examples', 'activity_ideas', 'books', 'videos', 'phrase_categories'].forEach(function(key) {
      if(!_this.get(key)) {
        _this.set(key, []);
      }
    });
  },
  category: DS.attr('string'),
  locale: DS.attr('string'),
  image: DS.attr('raw'),
  age_range: DS.attr('raw'),
  level_1_modeling_examples: DS.attr('raw'),
  level_2_modeling_examples: DS.attr('raw'),
  level_3_modeling_examples: DS.attr('raw'),
  activity_ideas: DS.attr('raw'),
  books: DS.attr('raw'),
  videos: DS.attr('raw'),
  phrase_categories: DS.attr('raw'),
  description: DS.attr('string'),
  verbs: DS.attr('string'),
  adjectives: DS.attr('string'),
  pronouns: DS.attr('string'),
  determiners: DS.attr('string'),
  time_based_words: DS.attr('string'),
  location_based_words: DS.attr('string'),
  other_words: DS.attr('string'),
  references: DS.attr('string')
});

export default Category;
