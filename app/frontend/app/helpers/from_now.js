import Ember from 'ember';

export default Ember.Helper.helper(function(params, hash) {
  return window.moment(params[0]).fromNow();
});
