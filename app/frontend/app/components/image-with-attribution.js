import Ember from 'ember';
import modal from '../utils/modal';

export default Ember.Component.extend({
  didInsertElement: function() {
    this.set('image_url', this.get('image.image_url'));
  },
  url_change: function() {
    var img = new Image();
    var _this = this;
    var done = false;
    img.onload = function() {
      done = true;
      if(encodeURI(_this.get('image.image_url')) == img.src) {
        _this.set('image_url', img.src);
      }
    };
    img.onerror = function() {
      done = true;
      if(encodeURI(_this.get('image.image_url')) == img.src) {
        _this.set('image_url', null);
      }
    };
    setTimeout(function() {
      if(!done) {
        if(encodeURI(_this.get('image.image_url')) == img.src) {
          _this.set('image_url', null);
        }
      }
    }, 1000);
    img.src = this.get('image.image_url');
    this.set('image_url', {loading: true});
  }.observes('image.image_url'),
  container_style: function() {
    var res = 'text-align: center; float: left; padding: 2px; margin: 0 10px 5px 0; overflow: hidden; position: relative;';
    if(this.get('border') !== false) {
      res = res + "border: 1px solid #ccc;";
    }
    if(this.get('fullscreen')) {
    } else if(this.get('tall')) {
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
  }.property('stretch', 'tall', 'border', 'fullscreen'),
  image_style: function() {
    var res = "width: 100%; object-fit: contain; object-position: center;";
    if(this.get('fullscreen')) {
      res = res + "max-height: 80vh;";
    } else if(this.get('tall')) {
      res = res + "max-height: 220px;";
    } else {
      res = res + "max-height: 120px;";
    }
    return Ember.String.htmlSafe(res);
  }.property('tall', 'fullscreen'),
  actions: {
    change_image: function() {
      var _this = this;
      modal.open('find-image', {label: this.get('label'), image: this.get('image')}).then(function(res) {
        if(res && res.image) {
          _this.sendAction('update_image', res.image, _this.get('ref'));
        }
      });;
    }
  }
});
