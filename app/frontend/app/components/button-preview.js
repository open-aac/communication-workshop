import Ember from 'ember';

export default Ember.Component.extend({
  tagName: 'span',
  didInsertElement: function() {
    this.redraw();
  },
  canvas_style: function() {
    if(this.get('fullscreen')) {
      var total = this.get('total_buttons') || 1;
      var rows = 1;
      var columns = 1;
      if(total === 1) {
      } else if(total === 2) {
        columns = 2;
      } else if(total <= 4) {
        rows = 2;
        columns = 2;
      } else if(total <= 6) {
        rows = 2;
        columns = 3;
      } else if(total <= 9) {
        rows = 3;
        columns = 4;
      } else {
        rows = Math.ceil(Math.sqrt(total));
        columns = rows;
      }
      var width = (((window.screen && window.screen.width) || window.innerWidth) * 0.8) / columns;
      var height = (((window.screen && window.screen.height) || window.innerHeight) * 0.8) / rows;
      width = Math.min(width, height);
      height = width;
      return Ember.String.htmlSafe('width: ' + width + 'px; height: ' + height + 'px;');
    } else if(this.get('small')) {
      return Ember.String.htmlSafe('width: 120px; height: 120px;');
    } else {
      return Ember.String.htmlSafe( 'width: 200px; height: 200px;');
    }
  }.property('small', 'fullscreen'),
  redraw: function() {
    var button = this.get('button');
    var $canvas = Ember.$(this.element).find("canvas");
    var _this = this;
    if($canvas[0] && button) {
      $canvas.attr('width', 1000);
      $canvas.attr('height', 1000);
      var context = $canvas[0].getContext('2d');
      var width = 1000;
      var height = 1000;
      var radius = 100;
      var pad = 40;
      context.save();
      context.clearRect(0, 0, width, height);
      context.beginPath();
      context.moveTo(pad + radius, pad);
      context.lineTo(width - pad - radius, pad);
      context.arcTo(width - pad, pad, width - pad, pad + radius, radius);
      context.lineTo(width - pad, height - pad - radius);
      context.arcTo(width - pad, height - pad, width - pad - radius, height - pad, radius);
      context.lineTo(pad + radius, height - pad);
      context.arcTo(pad, height - pad, pad, height - pad - radius, radius);
      context.lineTo(pad, pad + radius);
      context.arcTo(pad, pad, pad + radius, pad, radius);
      context.lineWidth = 50;
      context.fillStyle = button.background_color || '#fff';
      context.strokeStyle = button.border_color || '#ddd';
      context.stroke();
      context.fill();

      context.textAlign = 'center';
      var label = button.label || '';
      var size = 160;
      context.font = size + 'px Arial';
      while(size > 80 && context.measureText(label).width > (width - 30)) {
        size = size - 5;
        context.font = size + 'px Arial';
      }
      context.fillStyle = '#000';
      context.save();
      context.rect(pad, 0, width - pad - pad - context.lineWidth, height);
      context.clip();
      if(size <= 80 && context.measureText(label).width > (width - 30)) {
        var words = label.split(/\s/);
        var top = [];
        while(top.join(' ').length < label.length / 2) {
          top.push(words.shift());
        }
        context.fillText(top.join(' '), width / 2, pad + (pad / 3) + size);
        context.fillText(words.join(' '), width / 2, pad + (pad / 3) + size + size);
      } else {
        context.fillText(label, width / 2, pad + size);
      }
      context.restore();
      context.save();
      context.rect(pad + pad, pad + pad, width - pad - pad, height - pad - pad);
      context.clip();
      if(button.image_url) {
        var img = new Image();
        img.onload = function() {
          if(_this.get('button.id') === button.id) {
            // TODO: proportional drawing
            var width = img.width;
            var height = img.height;
            var x = 150, y = 250, w = 700, h = 700;
            if(width > height) {
              var scaled_height = h * (height / width);
              y = y + ((h - scaled_height) / 2);
            } else if(width < height) {
              var scaled_width = w * (width / height);
              x = x + ((w - scaled_width) / 2);
            }
            context.drawImage(img, x, y, w, h);
          }
        };
        img.src = button.image_url;
      }
      context.restore();
      context.restore();
    }
  }.observes('button.id'),
  aggressive_redraw: function() {
    if(this.get('watch')) {
      this.redraw();
    }
  }.observes('button.border_color', 'button.background_color', 'button.label', 'button.image_url', 'watch'),
});
