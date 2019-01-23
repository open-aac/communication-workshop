import Ember from 'ember';
import { helper as buildHelper } from '@ember/component/helper';

export default buildHelper(function(params, hash) {
  return window.moment(params[0]).fromNow();
});
