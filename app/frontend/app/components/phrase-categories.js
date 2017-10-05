import Ember from 'ember';
import i18n from '../utils/i18n';

export default Ember.Component.extend({
  willInsertElement: function() {
    this.update_filtered_list();
  },
  unused_categories: function() {
    var list = [
      i18n.t('questions', "Questions"),
      i18n.t('observations', "Observations"),
      i18n.t('social_phrases', "Social Phrases"),
      i18n.t('choice_making', "Choice-Making")
    ];
    (this.get('entries') || []).forEach(function(entry) {
      if(list.indexOf(entry.category) != -1) {
        list.splice(list.indexOf(entry.category), 1);
      }
    });
    return list.map(function(c) { return {label: c}; });
  }.property('entries.@each.category'),
  update_filtered_list: function() {
    var _this = this;
    (this.get('entries') || []).forEach(function(entry) {
      var list = entry.phrases.split(/,/);
      var result = [];
      var filter = _this.get('current_level.level');
      list.forEach(function(phrase) {
        phrase = phrase.replace(/^\s+/, '').replace(/\s$/, '');
        if(phrase.length > 0) {
          var pieces = phrase.split(/\s+/);
          if(filter === 1 && pieces.length <= 3) {
            result.push(phrase);
          } else if(filter === 2 && pieces.length <= 5 && pieces.length > 1) {
            result.push(phrase);
          } else if(filter === 3 && pieces.length >= 3) {
            result.push(phrase);
          } else if(filter === 'all') {
            result.push(phrase);
          }
        }
      });
      Ember.set(entry, 'filtered_phrases', result.join(', '));
    });
  }.observes('entries', 'current_level.level'),
  current_level: function() {
    var num = this.get('filter') || 1;
    if(this.get('filter_all')) {
      num = 'all';
    }
    var level = {
      level: num,
    };
    level['level_' + num] = true;
    return level;
  }.property('filter', 'filter_all'),
  actions: {
    delete_category: function(cat) {
      var idx = -1;
      this.get('entries').removeObject(cat);
    },
    add_category: function(cat) {
      this.get('entries').pushObject({});
    },
    set_category: function(entry, text) {
      Ember.set(entry, 'category', text);
    },
    set_level: function(level) {
      if(level === 'all' && !this.get('filter_all')) {
        this.set('filter_all', true);
      } else {
        this.set('filter_all', false);
        if(level !== 'all') {
          this.set('filter', level);
        }
      }
    }
  }
});
