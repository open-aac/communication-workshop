import Ember from 'ember';
import DS from 'ember-data';

var Focus = DS.Model.extend({
  didLoad: function() {
  },
  locale: DS.attr('string'),
  pending: DS.attr('boolean'),
  permissions: DS.attr('raw'),
  title: DS.attr('string'),
  author: DS.attr('string'),
  category: DS.attr('string'),
  words: DS.attr('string'),
  all_words: DS.attr('string'),
  image_url: DS.attr('string'),
  source_url: DS.attr('string'),
  helper_words: DS.attr('string'),
  approved_users: DS.attr('raw'),
  all_words_capitalized: function() {
    return (this.get('all_words') || '').replace(/\bi\b/g, 'I');
  }.property('all_words')
});
// Brown Bear
// Cordurouy
// Guess How Much I Love You
// Dear Zoo
// But not the hippopotamus
// Are you my monster
// Go dog go
// Blue hat, Green hat
// The Gruffalo
//  There Was an Old Lady Who Swallowed a Fly
// Wheels on The Bus
// Goodnight Moon
// The Very Hungry Caterpillar
// Are You My Mother
// Add categories/topics to focus sets
// http://www.aacintervention.com/home/180009852/180009852/Images/repeated%20line%20books.pdf


export default Focus;
