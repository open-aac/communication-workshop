import Ember from 'ember';
import DS from 'ember-data';
import session from '../utils/session';

var Word = DS.Model.extend({
  didLoad: function() {
    var _this = this;
    _this.set('session', session);
    ['usage_examples', 'level_1_modeling_examples', 'level_2_modeling_examples', 'level_3_modeling_examples', 'prompts', 'learning_projects', 'activity_ideas', 'books', 'topic_starters', 'videos'].forEach(function(key) {
      if(!_this.get(key)) {
        _this.set(key, []);
      }
    });
  },
  pending: DS.attr('boolean'),
  word: DS.attr('string'),
  locale: DS.attr('string'),
  image: DS.attr('raw'),
  revisions: DS.attr('raw'),
  revision_credit: DS.attr('string'),
  clear_revision_id: DS.attr('string'),
  approved_user_identifiers: DS.attr('raw'),
  permissions: DS.attr('raw'),
  usage_examples: DS.attr('raw'),
  level_1_modeling_examples: DS.attr('raw'),
  level_2_modeling_examples: DS.attr('raw'),
  level_3_modeling_examples: DS.attr('raw'),
  prompts: DS.attr('raw'),
  learning_projects: DS.attr('raw'),
  activity_ideas: DS.attr('raw'),
  books: DS.attr('raw'),
  topic_starters: DS.attr('raw'),
  videos: DS.attr('raw'),
  border_color: DS.attr('string'),
  background_color: DS.attr('string'),
  description: DS.attr('string'),
  parts_of_speech: DS.attr('string'),
  verbs: DS.attr('string'),
  adjectives: DS.attr('string'),
  adverbs: DS.attr('string'),
  pronouns: DS.attr('string'),
  determiners: DS.attr('string'),
  time_based_words: DS.attr('string'),
  location_based_words: DS.attr('string'),
  other_words: DS.attr('string'),
  related_categories: DS.attr('string'),
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

export default Word;


