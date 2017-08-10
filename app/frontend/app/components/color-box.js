import Ember from 'ember';

export default Ember.Component.extend({
  tagName: 'span',
  color_style: function() {
    var color = this.get('color');
    if(color && !color.match(/^(#[0-9a-f]{3}|#(?:[0-9a-f]{2}){2,4}|(rgb|hsl)a?\((\d+%?(deg|rad|grad|turn)?[,\s]+){2,3}[\s\/]*[\d\.]+%?\))$/)) {
      color = "";
    }


    var res = "display: inline-block; background: " + color + "; width: 30px; height: 30px; border-radius: 3px; border: 1px solid #222; vertical-align: middle;";
    return Ember.String.htmlSafe(res);
  }.property('color')
});
