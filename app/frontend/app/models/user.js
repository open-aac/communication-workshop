import Ember from 'ember';
import DS from 'ember-data';

var User = DS.Model.extend({
  user_name: DS.attr('string'),
  name: DS.attr('string'),
  admin: DS.attr('boolean'),
  permissions: DS.attr('raw'),
  current_words: DS.attr('raw'),
  starred_activity_ids: DS.attr('raw')
});

export default User;


