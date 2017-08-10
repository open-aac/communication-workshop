import Ember from "ember";
import DS from "ember-data";

var res = DS.RESTAdapter.extend({
  namespace: 'api/v1'
});

export default res;
