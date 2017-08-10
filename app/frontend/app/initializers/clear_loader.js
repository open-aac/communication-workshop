import Ember from 'ember';

export default {
  name: 'clear_loader',
  initialize: function() {
    document.getElementById('loading_box').remove();
  }
};
