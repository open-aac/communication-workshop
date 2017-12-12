import Ember from 'ember';

export default Ember.Component.extend({
  all_categories: function() {
    var list = (this.get('list') || "").split(/,/);
    var result = [];
    var locale = this.get('locale') || 'en';
    list.forEach(function(item) {
      item = item.replace(/^\s+/, '').replace(/\s$/, '');
      if(item.length > 0) {
        result.push({
          key: item.toLowerCase().replace(/\s+/g, '-'),
          text: item,
          locale: locale
        });
      }
    });
    if(result.length > 0) {
      result[result.length - 1].last = true;
    }
    return result;
  }.property('list', 'locale')
});
