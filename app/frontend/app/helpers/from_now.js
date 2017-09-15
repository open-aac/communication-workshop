import Ember from 'ember';

export default Ember.Helper.helper(function(params, hash) {
  return moment(params[0]).fromNow();
});
