import Ember from 'ember';
import i18n from '../utils/i18n';

export default Ember.Component.extend({
  tall: function() {
    return !this.get('update_revision_object');
  }.property('update_revision_object'),
  clear_on_change: function() {
    this.set('current_index', 0);
  }.property('entries', 'type'),
  current_entry: function() {
    var index = this.get('current_index') || 0;
    return (this.get('entries') || [])[index];
  }.property('entries', 'entries.length', 'current_index'),
  readable_index: function() {
    return (this.get('current_index') || 0) + 1;
  }.property('current_index'),
  prompt_type: function() {
    return this.get('type') === 'prompts';
  }.property('type'),
  description: function() {
    return this.get('type') === 'learning_projects' || this.get('type') == 'activity_ideas';
  }.property('type'),
  include_url: function() {
    return this.get('type') === 'learning_projects' || this.get('type') == 'activity_ideas' || this.get('type') === 'books' || this.get('type') == 'videos';
  }.property('type'),
  include_sentence: function() {
    return this.get('type') === 'modeling';
  }.property('type'),
  related_words: function() {
    return this.get('type') === 'topic_starters';
  }.property('type'),
  actions: {
    next: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.min(idx + 1, (this.get('entries') || []).length - 1));
    },
    previous: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.max(idx - 1, 0));
    },
    confirm_revision: function() {
      this.sendAction('update_revision_object', this.get('current_entry'), this.get('revision_attribute'));
    }
  }
});
