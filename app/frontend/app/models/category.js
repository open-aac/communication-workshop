import Ember from 'ember';
import DS from 'ember-data';
import session from '../utils/session';

var Category = DS.Model.extend({
  didLoad: function() {
    var _this = this;
    this.set('session', session);
    ['level_1_modeling_examples', 'level_2_modeling_examples', 'level_3_modeling_examples', 'activity_ideas', 'books', 'videos', 'phrase_categories'].forEach(function(key) {
      if(!_this.get(key)) {
        _this.set(key, []);
      }
    });
  },
  category: DS.attr('string'),
  locale: DS.attr('string'),
  image: DS.attr('raw'),
  revisions: DS.attr('raw'),
  clear_revision_id: DS.attr('string'),
  revision_credit: DS.attr('string'),
  approved_user_identifiers: DS.attr('raw'),
  permissions: DS.attr('raw'),
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
  references: DS.attr('string'),
  best_image_url: function() {
    var map = session.get('user.full_word_map') || [];
    var locale = this.get('locale');
    var word = this.get('word');
    var fallback = this.get('image.image_url');
    if(map[locale] && map[locale][word] && map[locale][word]['image'] && map[locale][word].image.image_url) {
      return map[locale][word].image.image_url;
    }
    return fallback;
  }.property('session.user.full_word_map', 'model.id'),
});

export default Category;
