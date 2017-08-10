import Ember from 'ember';
import i18n from '../utils/i18n';

export default Ember.Component.extend({
  tagName: 'span',
  licenseOptions: function() {
    return [
      {name: i18n.t('private_license', "Private (no reuse allowed)"), id: 'private'},
      {name: i18n.t('cc_by_license', "CC By (attribution only)"), id: 'CC By', url: 'http://creativecommons.org/licenses/by/4.0/'},
      {name: i18n.t('cc_by_sa_license', "CC By-SA (attribution + share-alike)"), id: 'CC By-SA', url: 'http://creativecommons.org/licenses/by-sa/4.0/'},
      {name: i18n.t('public_domain_license', "Public Domain"), id: 'public domain', url: 'http://creativecommons.org/publicdomain/zero/1.0/'}
    ];
  }.property(),
  private_license: function() {
    return this.get('record.license') === 'private';
  }.property('record.license')
});
