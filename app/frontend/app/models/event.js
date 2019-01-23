import Ember from 'ember';
import DS from 'ember-data';
import { htmlSafe } from '@ember/template';

var LearnEvent = DS.Model.extend({
  activity_id: DS.attr('string'),
  text: DS.attr('string'),
  tracked: DS.attr('date'),
  success_level: DS.attr('number'),
  notes: DS.attr('string'),
  user_id: DS.attr('string'),
  user_name: DS.attr('string'),
  face_class: function() {
    var level = this.get('success_level');
    if(level == 4) {
      return htmlSafe('face laugh');
    } else if(level == 3) {
      return htmlSafe('face happy');
    } else if(level == 2) {
      return htmlSafe('face neutral');
    } else if(level == 1) {
      return htmlSafe('face sad');
    } else {
      return null;
    }
  }.property('success_level')
});

export default LearnEvent;
