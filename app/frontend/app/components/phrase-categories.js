import Ember from 'ember';
import i18n from '../utils/i18n';
import Component from '@ember/component';
import { set as emberSet } from '@ember/object';

export default Component.extend({
  willInsertElement: function() {
    this.update_filtered_list();
  },
  unused_categories: function() {
    var list = [
      i18n.t('questions', "Questions/Seeking Information"),
      i18n.t('observations', "Observations/Providing Information"),
      i18n.t('social_phrases', "Social Phrases/Engagement"),
      i18n.t('choice_making', "Choice-Making/Refusal")
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
      var strings = [entry.phrases || ""];
      var pre_filtered = entry.level_1_phrases || entry.level_2_phrases || entry.level_3_phrases;
      var filter = _this.get('current_level.level');
      if(filter == 'all') {
        strings.push(entry.level_1_phrases || "");
        strings.push(entry.level_2_phrases || "");
        strings.push(entry.level_3_phrases || "");
      } else if(entry['level_' + filter + '_phrases']) {
        strings = [entry['level_' + filter + '_phrases']];
      }

      var list = strings.join(',').split(/,/);
      var result = [];
      list.forEach(function(phrase) {
        phrase = phrase.replace(/^\s+/, '').replace(/\s$/, '');
        if(phrase.length > 0) {
          var pieces = phrase.split(/\s+/);
          if(pre_filtered) {
            result.push(phrase);
          } else if(filter === 1 && pieces.length <= 3) {
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
      emberSet(entry, 'filtered_phrases', result);
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
      emberSet(entry, 'category', text);
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
