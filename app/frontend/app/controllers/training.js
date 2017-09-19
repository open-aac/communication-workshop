import Ember from 'ember';
import session from '../utils/session';

var str = "*Step One*\n[https://d18vdu4p71yql0.cloudfront.net/libraries/sclera/gesture%20done.png]\nWelcome to the wonderful world of AAC! Let's get started. Below you'll see a series of buttons. Each button will either speak what's on it, or link to another board of buttons. Let's try finding a few buttons.\nSee if you can find the button that speaks \"done\"\n{done}\n";
str = str + "*Step Two*\n[https://d18vdu4p71yql0.cloudfront.net/libraries/arasaac/to%20want.png]\nGreat! Many AAC users start with single-word sentences, and can later learn the combine words into more complex sentences.\nLet's try putting some words together! Hit \"I\", then \"want\" and then \"that\". You should be able to find all three without leaving the main board.\n{I,want,that}\n";
str = str + "*All Done!*\n[https://s3.amazonaws.com/opensymbols/libraries/arasaac/party_3.png]\nYou're amazing, great job!";

export default Ember.Controller.extend({
  update_stash: function() {
    if(!localStorage.training_stash || localStorage.training_stash.length == 0) {
      localStorage.training_stash = str;
    }
    this.set('stash', localStorage.training_stash);
    this.set('rules', localStorage.training_stash);
  },
  actions: {
    update: function() {
      localStorage.training_stash = this.get('stash');
      this.set('rules', this.get('stash'));
      this.set('reset_id', (new Date()).getTime());
    },
    reset: function() {
      this.set('stash', str);
      this.send('update');
    }
  }
});
