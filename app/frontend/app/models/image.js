import Ember from 'ember';
import DS from 'ember-data';

var ImageModel = DS.Model.extend({
  didLoad: function() {
  },
  user_id: DS.attr('string'),
  url: DS.attr('string')
});

export default ImageModel;
