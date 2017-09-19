import Ember from 'ember';
import session from '../utils/session';

export default Ember.Controller.extend({
  update_stash: function() {
    if(!localStorage.training_stash || localStorage.training_stash.length == 0) {
      var str = "*Step One*\nWelcome to the wonderful world of AAC! Let's get started, and try finding a few buttons. See if you can find the button that speaks \"done\"\n{done}\n";
      str = str + "*Step Two*\nGreat! Now let's put some words together! Hit \"I\", then \"want\" and then \"that\"\n{I,want,that}\n";
      str = str + "*All Done!*\nYou're amazing, great job!";
      localStorage.training_stash = str;
    }
    this.set('stash', localStorage.training_stash);
  },
  actions: {
    update: function() {
      localStorage.training_stash = this.get('stash');
    }
  }
});
