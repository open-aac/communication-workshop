import Ember from 'ember';
import { htmlSafe } from '@ember/template';
import EmberObject from '@ember/object';
import { assign } from '@ember/polyfills';
import { get as emberGet } from '@ember/object';

Ember.templateHelpers = Ember.templateHelpers || {};

Ember.templateHelpers.locale = function(str) {
  str = str.replace(/-/g, '_');
  var pieces = str.split(/_/);
  if(pieces[0]) { pieces[0] = pieces[0].toLowerCase(); }
  if(pieces[1]) { pieces[1] = pieces[1].toUpperCase(); }
  str = pieces[0] + "_" + pieces[1];
  var res = i18n.get('locales')[str];
  if(!res) {
    res = i18n.get('locales')[pieces[0]];
  }
  res = res || i18n.t('unknown_locale', "Unknown");
  return res;
};

Ember.templateHelpers.list = function(list, type) {
  return list.join(', ');
};
Ember.templateHelpers.t = function(str, options) {
  // TODO: options values are NOT bound, so this doesn't work for our purposes
  // prolly needs to be rewritten as a custom view or something
  return new htmlSafe(i18n.t(options.key, str, options));
};

Ember.templateHelpers.is_equal = function(lhs, rhs) {
  return lhs == rhs;
};

var i18n = EmberObject.extend({
  t: function(key, str, options) {
    var terms = str.match(/%{(\w+)}/g);
    var value;
    options = assign({}, options);
    if(options && !options.hash) { options.hash = options; }
    for(var idx = 0; terms && idx < terms.length; idx++) {
      var word = terms[idx].match(/%{(\w+)}/)[1];
      if(options[word] !== undefined && options[word] !== null) {
        value = options[word];
        if(options.increment == word || options.hash.increment == word) { value++; }
        str = str.replace(terms[idx], value);
      } else if(options.hash && options.hash[word] !== undefined && options.hash[word] !== null) {
        value = options.hash[word];
        if(options.increment == word || options.hash.increment == word) { value++; }
        if(options.hashTypes) {
          // TODO: pretty sure this isn't used anymore
          if(options.hashTypes[word] == 'ID') {
            value = emberGet(options.hashContexts[word], options.hash[word].toString());
            value = value || options.hash[word];
          }
        }
        str = str.replace(terms[idx], value);
      }
    }

    if(options && options.hash && options.hash.count !== undefined) {
      var count = options.hash.count;
      if(count && count.length) { count = count.length; }
      if(options.increment == 'count' || options.hash.increment == 'count') { count++; }
      if(count != 1) {
        str = count + " " + this.pluralize(str);
      } else {
        str = count + " " + str;
      }
    }
    return str;
  },
}).create({
});

export default i18n;
