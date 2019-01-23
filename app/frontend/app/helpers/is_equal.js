import Ember from 'ember';
import { helper as buildHelper } from '@ember/component/helper';

export default buildHelper(function(params, hash) {
  return Ember.templateHelpers.is_equal(params[0], params[1]);
});
