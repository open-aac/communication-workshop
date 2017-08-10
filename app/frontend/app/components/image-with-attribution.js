import Ember from 'ember';
import modal from '../utils/modal';

export default Ember.Component.extend({
  didInsertElement: function() {
  },
  container_style: function() {
    var res = 'text-align: center; float: left; padding: 2px; margin: 0 10px 5px 0; overflow: hidden; position: relative;';
    if(this.get('border') !== false) {
      res = res + "border: 1px solid #ccc;";
    }
    if(this.get('tall')) {
      res = res + "height: 222px;";
    } else {
      res = res + "height: 122px;";
    }
    if(this.get('stretch')) {
      res = res + "width: 100%;";
    } else {
      res = res + "width: 122px;";
    }
    return Ember.String.htmlSafe(res);
  }.property('stretch', 'tall', 'border'),
  image_style: function() {
    var res = "width: 100%; object-fit: contain; object-position: center;";
    if(this.get('tall')) {
      res = res + "max-height: 220px;";
    } else {
      res = res + "max-height: 120px;";
    }
    return Ember.String.htmlSafe(res);
  }.property('tall'),
  actions: {
    change_image: function() {
      var _this = this;
      modal.open('find-image', {label: this.get('label'), image: this.get('image')}).then(function(res) {
        if(res && res.image) {
          _this.sendAction('update_image', res.image);
        }
      });;
    }
  }
});
