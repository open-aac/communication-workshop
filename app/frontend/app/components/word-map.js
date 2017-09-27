import Ember from 'ember';
import i18n from '../utils/i18n';

export default Ember.Component.extend({
  box_style: function() {
    var res = 'border: 2px solid #ddd; padding: 10px; border-radius: 3px;';
    if(!this.get('showing_all')) {
      res = res + 'max-height: 300px; overflow: auto';
    }
    return Ember.String.htmlSafe(res);
  }.property('showing_all'),
  allow_show_all: function() {
    return this.get('buttons.length') > 10 && !this.get('showing_all');
  }.property('buttons.length', 'showing_all'),
  buttons: function() {
    var result = [];
    var locales = this.get('map') || {};
    for(var locale in locales) {
      var map = locales[locale];
      for(var idx in map) {
        if(map && map[idx]) {
          map[idx].sort_label = (map[idx].label || 'zzzzz').toLowerCase();
          map[idx].locale = map[idx].locale || locale;
          result.push(map[idx]);
        }
      }
    }
    result = result.sortBy('sort_label');
    return result;
  }.property('map'),
  actions: {
    show_all: function() {
      this.set('showing_all', true);
    }
  }
});
